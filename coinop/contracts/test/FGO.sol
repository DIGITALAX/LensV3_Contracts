// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "./../src/ChildFGO.sol";
import "./../src/ParentFGO.sol";
import "./../src/CustomCompositeNFT.sol";
import "./../src/FGOAccessControl.sol";
import "./../src/FGOMarket.sol";
import "./../src/lib/PrintSplitsData.sol";
import "./../src/lib/TestToken.sol";

contract FGOTest is Test {
    ParentFGO parentFGO;
    ChildFGO childFGO;
    CustomCompositeNFT customComposite;
    FGOAccessControl accessControl;
    PrintSplitsData splitsData;
    FGOMarket market;
    TestToken mona;
    TestToken wgho;

    address admin = address(1);
    address buyer = address(3);
    address fulfiller = address(6);

    function setUp() public {
        vm.startPrank(admin);
        PrintAccessControl accessControlPrint = new PrintAccessControl();
        splitsData = new PrintSplitsData(address(accessControlPrint));

        accessControl = new FGOAccessControl();
        childFGO = new ChildFGO(address(accessControl));
        parentFGO = new ParentFGO(address(childFGO), address(accessControl));
        customComposite = new CustomCompositeNFT(address(accessControl));
        market = new FGOMarket(
            address(accessControl),
            address(customComposite),
            address(parentFGO),
            address(splitsData),
            address(childFGO)
        );

        mona = new TestToken();
        wgho = new TestToken();

        accessControl.setFulfiller(fulfiller);
        childFGO.setParentFGO(address(parentFGO));
        parentFGO.setMarket(address(market));
        customComposite.setMarket(address(market));

        splitsData.addCurrency(
            address(mona),
            1000000000000000000,
            22670000000000000000
        );
        splitsData.addCurrency(
            address(wgho),
            1000000000000000000,
            1000000000000000000
        );
        splitsData.setSplits(
            address(mona),
            5000000000000000000,
            351957765100000000,
            1
        );
        splitsData.setSplits(
            address(wgho),
            5000000000000000000,
            8000000000000000000,
            1
        );
        vm.stopPrank();
    }

    function testCreateFGO() public {
        vm.startPrank(admin);
        childFGO.createChildFGO(
            FGOLibrary.ChildMetadata({
                uri: "childuri1",
                price: 5000000000000000000
            })
        );
        childFGO.createChildFGO(
            FGOLibrary.ChildMetadata({
                uri: "childuri2",
                price: 3000000000000000000
            })
        );
        childFGO.createChildFGO(
            FGOLibrary.ChildMetadata({
                uri: "childuri3",
                price: 1000000000000000000
            })
        );
        childFGO.createChildFGO(
            FGOLibrary.ChildMetadata({
                uri: "childuri4",
                price: 5000000000000000000
            })
        );

        uint256[] memory childIds = new uint256[](2);
        childIds[0] = 1;
        childIds[1] = 3;

        parentFGO.createParentFGO(
            FGOLibrary.ParentMetadata({
                childIds: childIds,
                uri: "parenturi1",
                poster: "posteruri1",
                price: 150000000000000000000,
                printType: 4
            })
        );

        uint256[] memory childIdsTwo = new uint256[](4);
        childIdsTwo[0] = 1;
        childIdsTwo[1] = 2;
        childIdsTwo[2] = 3;
        childIdsTwo[3] = 4;

        parentFGO.createParentFGO(
            FGOLibrary.ParentMetadata({
                childIds: childIdsTwo,
                uri: "parenturi2",
                poster: "posteruri2",
                price: 182000000000000000000,
                printType: 3
            })
        );
        vm.stopPrank();
        assertEq(parentFGO.getTokenSupply(), 0);
        assertEq(childFGO.getTokenSupply(), 4);
        assertEq(parentFGO.getParentSupply(), 2);
        assertEq(parentFGO.getParentURI(1), "parenturi1");
        assertEq(parentFGO.getParentURI(2), "parenturi2");
        assertEq(parentFGO.getParentPoster(1), "posteruri1");
        assertEq(parentFGO.getParentPoster(2), "posteruri2");
        assertEq(parentFGO.getParentPrice(1), 150000000000000000000);
        assertEq(parentFGO.getParentPrice(2), 182000000000000000000);
        assertEq(parentFGO.getParentPrintType(1), 4);
        assertEq(parentFGO.getParentPrintType(2), 3);
        assertEq(
            keccak256(abi.encodePacked(parentFGO.getParentChildIds(1))),
            keccak256(abi.encodePacked([1, 3]))
        );
        assertEq(
            keccak256(abi.encodePacked(parentFGO.getParentChildIds(2))),
            keccak256(abi.encodePacked([1, 2, 3, 4]))
        );

        assertEq(childFGO.getChildURI(1), "childuri1");
        assertEq(childFGO.getChildURI(2), "childuri2");
        assertEq(childFGO.getChildURI(3), "childuri3");
        assertEq(childFGO.getChildURI(4), "childuri4");
        assertEq(childFGO.getChildPrice(1), 5000000000000000000);
        assertEq(childFGO.getChildPrice(2), 3000000000000000000);
        assertEq(childFGO.getChildPrice(3), 1000000000000000000);
        assertEq(childFGO.getChildPrice(4), 5000000000000000000);

        assertEq(childFGO.uri(1), "childuri1");
        assertEq(childFGO.uri(2), "childuri2");
        assertEq(childFGO.uri(3), "childuri3");
        assertEq(childFGO.uri(4), "childuri4");
    }

    function testBuyFGO() public {
        testCreateFGO();

        vm.prank(admin);
        wgho.transfer(buyer, 156000000000000000000);

        vm.prank(buyer);
        wgho.approve(address(market), 156000000000000000000);

        FGOLibrary.BuyParms[] memory _params = new FGOLibrary.BuyParms[](1);

        _params[0] = FGOLibrary.BuyParms({
            details: "details",
            uri: "customuri",
            currency: address(wgho),
            parentId: 1
        });

        uint256 buyerBefore = wgho.balanceOf(buyer);
        uint256 fulfillerBefore = wgho.balanceOf(fulfiller);

        vm.prank(buyer);
        market.buyComposites(_params);

        uint256 _exchangeRateWgho = splitsData.getCurrencyRate(address(wgho));
        uint256 _weiDivisorWgho = splitsData.getCurrencyWei(address(wgho));
        uint256 _wghomount = (156000000000000000000 * _weiDivisorWgho) /
            _exchangeRateWgho;

        assertEq(buyerBefore - _wghomount, wgho.balanceOf(buyer));
        assertEq(fulfillerBefore + _wghomount, wgho.balanceOf(fulfiller));
        assertEq(customComposite.balanceOf(buyer), 1);
        assertEq(childFGO.balanceOf(buyer, 1), 1);
        assertEq(childFGO.balanceOf(buyer, 3), 1);

        assertEq(market.getOrderTokenId(1), 1);
        assertEq(market.getOrderParentId(1), 1);
        assertEq(market.getOrderParentTokenId(1), 1);
        assertEq(market.getOrderBuyer(1), buyer);
        assertEq(market.getOrderTotalPrice(1), _wghomount);
        assertEq(
            keccak256(abi.encodePacked(market.getOrderStatus(1))),
            keccak256(abi.encodePacked(FGOLibrary.OrderStatus.Designing))
        );
        assertEq(market.getOrderCurrency(1), address(wgho));
        assertEq(market.getOrderDetails(1), "details");
        assertEq(market.getOrderIsFulfilled(1), false);
        assertEq(market.getOrderSupply(), 1);
        assertEq(
            keccak256(abi.encodePacked(market.getBuyerToOrderIds(buyer))),
            keccak256(abi.encodePacked([1]))
        );

        assertEq(customComposite.tokenURI(1), "customuri");
        assertEq(parentFGO.tokenURI(1), "parenturi1");
    }

    function testBuyFGOMultiple() public {
        testBuyFGO();

        vm.prank(admin);
        wgho.transfer(buyer, 156000000000000000000);

        vm.prank(buyer);
        wgho.approve(address(market), 156000000000000000000);

        vm.prank(admin);
        mona.transfer(buyer, 196000000000000000000);

        vm.prank(buyer);
        mona.approve(address(market), 196000000000000000000);

        FGOLibrary.BuyParms[] memory _params = new FGOLibrary.BuyParms[](2);

        _params[0] = FGOLibrary.BuyParms({
            details: "details1",
            uri: "customuri1",
            currency: address(wgho),
            parentId: 1
        });

        _params[1] = FGOLibrary.BuyParms({
            details: "details2",
            uri: "customuri2",
            currency: address(mona),
            parentId: 2
        });

        uint256 buyerBeforewhgo = wgho.balanceOf(buyer);
        uint256 fulfillerBeforewhgo = wgho.balanceOf(fulfiller);
        uint256 buyerBeforemona = mona.balanceOf(buyer);
        uint256 fulfillerBeforemona = mona.balanceOf(fulfiller);

        vm.prank(buyer);
        market.buyComposites(_params);

        uint256 _exchangeRateMona = splitsData.getCurrencyRate(address(mona));
        uint256 _weiDivisorMona = splitsData.getCurrencyWei(address(mona));
        uint256 _monaAmount = (196000000000000000000 * _weiDivisorMona) /
            _exchangeRateMona;

        uint256 _exchangeRateWgho = splitsData.getCurrencyRate(address(wgho));
        uint256 _weiDivisorWgho = splitsData.getCurrencyWei(address(wgho));
        uint256 _wghomount = (156000000000000000000 * _weiDivisorWgho) /
            _exchangeRateWgho;

        assertEq(market.getOrderTokenId(2), 2);
        assertEq(market.getOrderParentId(2), 1);
        assertEq(market.getOrderParentTokenId(2), 2);
        assertEq(market.getOrderBuyer(2), buyer);
        assertEq(market.getOrderTotalPrice(2), _wghomount);
        assertEq(
            keccak256(abi.encodePacked(market.getOrderStatus(2))),
            keccak256(abi.encodePacked(FGOLibrary.OrderStatus.Designing))
        );
        assertEq(market.getOrderCurrency(2), address(wgho));
        assertEq(market.getOrderDetails(2), "details1");
        assertEq(market.getOrderIsFulfilled(2), false);
        assertEq(market.getOrderSupply(), 3);
        assertEq(
            keccak256(abi.encodePacked(market.getBuyerToOrderIds(buyer))),
            keccak256(abi.encodePacked([1, 2, 3]))
        );

        assertEq(market.getOrderTokenId(3), 3);
        assertEq(market.getOrderParentId(3), 2);
        assertEq(market.getOrderParentTokenId(3), 3);
        assertEq(market.getOrderBuyer(3), buyer);
        assertEq(market.getOrderTotalPrice(3), _monaAmount);
        assertEq(
            keccak256(abi.encodePacked(market.getOrderStatus(3))),
            keccak256(abi.encodePacked(FGOLibrary.OrderStatus.Designing))
        );
        assertEq(market.getOrderCurrency(3), address(mona));
        assertEq(market.getOrderDetails(3), "details2");
        assertEq(market.getOrderIsFulfilled(3), false);

        assertEq(customComposite.tokenURI(2), "customuri1");
        assertEq(parentFGO.tokenURI(2), "parenturi1");

        assertEq(customComposite.tokenURI(3), "customuri2");
        assertEq(parentFGO.tokenURI(3), "parenturi2");

        assertEq(buyerBeforewhgo - _wghomount, wgho.balanceOf(buyer));
        assertEq(fulfillerBeforewhgo + _wghomount, wgho.balanceOf(fulfiller));

        assertEq(customComposite.balanceOf(buyer), 3);
        assertEq(parentFGO.balanceOf(buyer), 3);
        assertEq(childFGO.balanceOf(buyer, 1), 3);
        assertEq(childFGO.balanceOf(buyer, 2), 1);
        assertEq(childFGO.balanceOf(buyer, 3), 3);
        assertEq(childFGO.balanceOf(buyer, 4), 1);

        assertEq(buyerBeforemona - _monaAmount, mona.balanceOf(buyer));
        assertEq(fulfillerBeforemona + _monaAmount, mona.balanceOf(fulfiller));
    }

    function testBurnDeletesParentAndChildren() public {
        testBuyFGO();

        assertEq(parentFGO.ownerOf(1), buyer);
        assertEq(childFGO.balanceOf(buyer, 1), 1);
        assertEq(childFGO.balanceOf(buyer, 3), 1);

        vm.prank(buyer);
        parentFGO.burnParent(1);

        vm.expectRevert();
        parentFGO.ownerOf(1);

        assertEq(childFGO.balanceOf(buyer, 1), 0);
        assertEq(childFGO.balanceOf(buyer, 3), 0);
    }

    function testTransferAlsoMovesChildren() public {
        testBuyFGO();

        address receiver = address(9);

        assertEq(parentFGO.ownerOf(1), buyer);
        assertEq(childFGO.balanceOf(buyer, 1), 1);
        assertEq(childFGO.balanceOf(buyer, 3), 1);
        assertEq(childFGO.balanceOf(receiver, 1), 0);
        assertEq(childFGO.balanceOf(receiver, 3), 0);

        vm.prank(buyer);
        parentFGO.transferFrom(buyer, receiver, 1);

        assertEq(parentFGO.ownerOf(1), receiver);
        assertEq(childFGO.balanceOf(receiver, 1), 1);
        assertEq(childFGO.balanceOf(receiver, 3), 1);

        assertEq(childFGO.balanceOf(buyer, 1), 0);
        assertEq(childFGO.balanceOf(buyer, 3), 0);
    }

    function testCannotBurnOrTransferChildrenDirectly() public {
    testBuyFGO();

    vm.startPrank(buyer);
    vm.expectRevert(); 
    childFGO.burn(buyer, 1);
    vm.stopPrank();

    vm.startPrank(buyer);
    vm.expectRevert(); 
    childFGO.safeTransferFrom(buyer, address(99), 1, 1, "");
    vm.stopPrank();
}
}
