// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.26;

import "./../src/actions/ChromadinAction.sol";
import "./../src/actions/F3MAction.sol";
import "./../src/actions/CoinOpAction.sol";
import "forge-std/Test.sol";
import "../src/CollectionCreator.sol";
import "../src/MarketCreator.sol";
import "../src/NFTCreator.sol";
import "../src/PrintAccessControl.sol";
import "../src/PrintSplitsData.sol";
import "../src/PrintNFT.sol";
import "../src/TestToken.sol";

contract ActionsTest is Test {
    CollectionCreator collectionCreator;
    MarketCreator marketCreator;
    NFTCreator nftCreator;
    PrintAccessControl accessControl;
    PrintSplitsData splitsData;
    PrintNFT f3mNFT;
    PrintNFT chromadinNFT;
    PrintNFT coinopNFT;
    F3MAction f3mAction;
    CoinOpAction coinopAction;
    ChromadinAction chromadinAction;
    TestToken mona;
    TestToken wgho;

    address admin = address(1);
    address designer = address(3);
    address designer2 = address(5);
    address actionHub = address(4);
    address fulfiller = address(6);
    address buyer = address(7);

    function setUp() public {
        vm.startPrank(admin);
        accessControl = new PrintAccessControl();
        splitsData = new PrintSplitsData(address(accessControl));
        nftCreator = new NFTCreator(address(accessControl));
        collectionCreator = new CollectionCreator(
            address(accessControl),
            address(splitsData)
        );
        f3mNFT = new PrintNFT("F3MNFT", "F3M", address(accessControl), 3);
        chromadinNFT = new PrintNFT(
            "ChromadinNFT",
            "CHROMA",
            address(accessControl),
            0
        );
        coinopNFT = new PrintNFT(
            "CoinOpNFT",
            "COIN",
            address(accessControl),
            1
        );
        marketCreator = new MarketCreator(
            address(accessControl),
            address(splitsData),
            address(nftCreator),
            address(collectionCreator)
        );

        coinopAction = new CoinOpAction(
            actionHub,
            address(accessControl),
            address(splitsData),
            address(marketCreator),
            address(collectionCreator)
        );
        chromadinAction = new ChromadinAction(
            actionHub,
            address(accessControl),
            address(splitsData),
            address(marketCreator),
            address(collectionCreator)
        );
        mona = new TestToken();
        wgho = new TestToken();

        accessControl.addFulfiller(fulfiller);
        nftCreator.setMarketCreatorAddress(address(marketCreator));
        chromadinNFT.setNFTCreator(address(nftCreator));
        chromadinNFT.setCollectionCreatorAddress(address(collectionCreator));
        f3mNFT.setNFTCreator(address(nftCreator));
        f3mNFT.setCollectionCreatorAddress(address(collectionCreator));
        coinopNFT.setNFTCreator(address(nftCreator));
        coinopNFT.setCollectionCreatorAddress(address(collectionCreator));

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

        nftCreator.setNFTOrigin(address(chromadinNFT), 0);
        nftCreator.setNFTOrigin(address(f3mNFT), 3);
        nftCreator.setNFTOrigin(address(coinopNFT), 1);
        collectionCreator.setMarketCreatorAddress(address(marketCreator));
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

        splitsData.setSplits(
            address(mona),
            5000000000000000000,
            1099868016000000000,
            2
        );
        splitsData.setSplits(
            address(wgho),
            5000000000000000000,
            2500000000000000000,
            2
        );

        accessControl.addDesigner(designer);
        accessControl.addDesigner(designer2);
        vm.stopPrank();

        vm.prank(designer2);
        f3mAction = new F3MAction(
            actionHub,
            address(accessControl),
            address(splitsData),
            address(marketCreator),
            address(collectionCreator)
        );

        vm.startPrank(admin);
        accessControl.addAction(address(chromadinAction));
        accessControl.addAction(address(coinopAction));
        accessControl.addAction(address(f3mAction));
        vm.stopPrank();
    }

    function testChromadin() public {
        vm.prank(designer);
        collectionCreator.createDrop("ipfs://drop_uri");

        KeyValue[] memory _keys = new KeyValue[](1);

        PrintLibrary.CollectionInitParams memory params = PrintLibrary
            .CollectionInitParams({
                acceptedTokens: new address[](2),
                uri: "ipfs://QmdxnkW6Ds3Si4kNgVuiC5Z6R6MyLTfPxAK1BcFS6r5VUW",
                fulfiller: fulfiller,
                price: 1 ether,
                dropId: 1,
                amount: 10,
                printType: 6,
                unlimited: false
            });

        params.acceptedTokens[0] = address(mona);
        params.acceptedTokens[1] = address(wgho);

        _keys[0] = KeyValue({
            key: keccak256("lens.param.collectionCreator"),
            value: abi.encode(params)
        });

        vm.prank(actionHub);
        chromadinAction.configure(designer, address(0), 12345, _keys);

        assertEq(collectionCreator.getCollectionDesigner(1), designer);
        assertEq(collectionCreator.getCollectionAmount(1), 10);
        assertEq(collectionCreator.getCollectionFrozen(1), false);
        assertEq(collectionCreator.getCollectionDropId(1), 1);
        assertEq(collectionCreator.getCollectionFulfiller(1), fulfiller);
        assertEq(collectionCreator.getCollectionOrigin(1), 0);
        assertEq(collectionCreator.getCollectionPostId(1), 12345);
        assertEq(collectionCreator.getCollectionPrice(1), 1 ether);
        assertEq(collectionCreator.getCollectionPrintType(1), 6);
        assertEq(collectionCreator.getCollectionSupply(), 1);
        assertEq(collectionCreator.getCollectionUnlimited(1), false);
        assertEq(
            collectionCreator.getCollectionURI(1),
            "ipfs://QmdxnkW6Ds3Si4kNgVuiC5Z6R6MyLTfPxAK1BcFS6r5VUW"
        );
        assertEq(collectionCreator.getDropDesigner(1), designer);
        assertEq(collectionCreator.getDropURI(1), "ipfs://drop_uri");
        assertEq(collectionCreator.getDropSupply(), 1);

        assertEq(
            keccak256(
                abi.encodePacked(
                    collectionCreator.getCollectionAcceptedTokens(1)
                )
            ),
            keccak256(abi.encodePacked(params.acceptedTokens))
        );
        assertEq(
            collectionCreator.getCollectionMintedTokenIds(1),
            new uint256[](0)
        );
        assertEq(
            keccak256(
                abi.encodePacked(collectionCreator.getDropCollectionIds(1))
            ),
            keccak256(abi.encodePacked([1]))
        );

        vm.prank(admin);
        mona.transfer(buyer, 100 ether);

        vm.prank(buyer);
        mona.approve(address(chromadinAction), 1.5 ether);

        KeyValue[] memory _keysExecute = new KeyValue[](1);
        string[] memory _details = new string[](1);
        address[] memory _currencies = new address[](1);
        uint256[] memory _collectionIds = new uint256[](0);
        uint8[] memory _amounts = new uint8[](1);

        _currencies[0] = address(mona);
        _amounts[0] = 1;

        _keysExecute[0] = KeyValue({
            key: keccak256("lens.param.buyChromadin"),
            value: abi.encode(
                _details,
                _currencies,
                _collectionIds,
                _amounts,
                buyer
            )
        });

        uint256 designerBefore = mona.balanceOf(designer);
        uint256 buyerBefore = mona.balanceOf(buyer);

        vm.prank(actionHub);
        chromadinAction.execute(buyer, address(0), 12345, _keysExecute);

        assertEq(
            keccak256(
                abi.encodePacked(
                    collectionCreator.getCollectionMintedTokenIds(1)
                )
            ),
            keccak256(abi.encodePacked([1]))
        );

        assertEq(chromadinNFT.tokenURI(1), params.uri);
        assertEq(chromadinNFT.getTokenSupply(), 1);
        assertEq(chromadinNFT.balanceOf(buyer), 1);

        assertEq(marketCreator.getOrderAmount(1), 1);
        assertEq(marketCreator.getOrderBuyer(1), buyer);
        assertEq(marketCreator.getOrderCollectionId(1), 1);
        assertEq(marketCreator.getOrderCurrency(1), address(mona));
        assertEq(marketCreator.getOrderDetails(1), "");
        assertEq(marketCreator.getOrderFulfiller(1), fulfiller);
        assertEq(marketCreator.getOrderIsFulfilled(1), true);
        assertEq(
            keccak256(abi.encodePacked(marketCreator.getOrderStatus(1))),
            keccak256(abi.encodePacked(PrintLibrary.OrderStatus.Fulfilled))
        );
        assertEq(marketCreator.getOrderSupply(), 1);
        assertEq(marketCreator.getOrderTotalPrice(1), 1 ether);
        assertEq(
            keccak256(abi.encodePacked(marketCreator.getOrderTokenIds(1))),
            keccak256(abi.encodePacked([1]))
        );
        assertEq(
            keccak256(
                abi.encodePacked(marketCreator.getBuyerToOrderIds(buyer))
            ),
            keccak256(abi.encodePacked([1]))
        );

        uint256 _exchangeRate = splitsData.getCurrencyRate(address(mona));
        uint256 _weiDivisor = splitsData.getCurrencyWei(address(mona));
        uint256 _tokenAmount = (collectionCreator.getCollectionPrice(1) *
            _weiDivisor) / _exchangeRate;

        assertEq(mona.balanceOf(designer), designerBefore + _tokenAmount);
        assertEq(mona.balanceOf(buyer), buyerBefore - _tokenAmount);
    }

    function testF3M() public {
        testChromadin();

        vm.prank(designer2);
        collectionCreator.createDrop("ipfs://drop_uri2");

        KeyValue[] memory _keys = new KeyValue[](1);

        PrintLibrary.CollectionInitParams memory params = PrintLibrary
            .CollectionInitParams({
                acceptedTokens: new address[](1),
                uri: "ipfs://QmdxnkW6Ds3Si4kNgVuiC5Z6R6MyLTfPxAK1BcFS6r5VUW",
                fulfiller: fulfiller,
                price: 0.2 ether,
                dropId: 2,
                amount: 3,
                printType: 7,
                unlimited: false
            });

        params.acceptedTokens[0] = address(wgho);

        _keys[0] = KeyValue({
            key: keccak256("lens.param.collectionCreator"),
            value: abi.encode(params)
        });

        vm.prank(actionHub);
        f3mAction.configure(designer2, address(0), 1111, _keys);

        assertEq(collectionCreator.getCollectionDesigner(2), designer2);
        assertEq(collectionCreator.getCollectionAmount(2), 3);
        assertEq(collectionCreator.getCollectionFrozen(2), false);
        assertEq(collectionCreator.getCollectionDropId(2), 2);
        assertEq(collectionCreator.getCollectionFulfiller(2), fulfiller);
        assertEq(collectionCreator.getCollectionOrigin(2), 3);
        assertEq(collectionCreator.getCollectionPostId(2), 1111);
        assertEq(collectionCreator.getCollectionPrice(2), 0.2 ether);
        assertEq(collectionCreator.getCollectionPrintType(2), 7);
        assertEq(collectionCreator.getCollectionSupply(), 2);
        assertEq(collectionCreator.getCollectionUnlimited(2), false);
        assertEq(
            collectionCreator.getCollectionURI(2),
            "ipfs://QmdxnkW6Ds3Si4kNgVuiC5Z6R6MyLTfPxAK1BcFS6r5VUW"
        );
        assertEq(collectionCreator.getDropDesigner(2), designer2);
        assertEq(collectionCreator.getDropURI(2), "ipfs://drop_uri2");
        assertEq(collectionCreator.getDropSupply(), 2);

        assertEq(
            keccak256(
                abi.encodePacked(
                    collectionCreator.getCollectionAcceptedTokens(2)
                )
            ),
            keccak256(abi.encodePacked(params.acceptedTokens))
        );
        assertEq(
            collectionCreator.getCollectionMintedTokenIds(2),
            new uint256[](0)
        );
        assertEq(
            keccak256(
                abi.encodePacked(collectionCreator.getDropCollectionIds(2))
            ),
            keccak256(abi.encodePacked([2]))
        );

        vm.prank(admin);
        wgho.transfer(buyer, 100 ether);

        vm.prank(buyer);
        wgho.approve(address(f3mAction), 1.5 ether);

        KeyValue[] memory _keysExecute = new KeyValue[](1);
        string[] memory _details = new string[](1);
        address[] memory _currencies = new address[](1);
        uint256[] memory _collectionIds = new uint256[](0);
        uint8[] memory _amounts = new uint8[](1);

        _details[0] = "encrypted";
        _currencies[0] = address(wgho);
        _amounts[0] = 2;

        _keysExecute[0] = KeyValue({
            key: keccak256("lens.param.buyF3M"),
            value: abi.encode(
                _details,
                _currencies,
                _collectionIds,
                _amounts,
                buyer
            )
        });

        uint256 designerBefore = wgho.balanceOf(designer2);
        uint256 buyerBefore = wgho.balanceOf(buyer);

        vm.prank(actionHub);
        f3mAction.execute(buyer, address(0), 1111, _keysExecute);

        assertEq(
            keccak256(
                abi.encodePacked(
                    collectionCreator.getCollectionMintedTokenIds(2)
                )
            ),
            keccak256(abi.encodePacked([1, 2]))
        );
        assertEq(f3mNFT.tokenURI(1), params.uri);
        assertEq(f3mNFT.tokenURI(2), params.uri);
        assertEq(f3mNFT.getTokenSupply(), 2);
        assertEq(f3mNFT.balanceOf(buyer), 2);

        assertEq(marketCreator.getOrderAmount(2), 2);
        assertEq(marketCreator.getOrderBuyer(2), buyer);
        assertEq(marketCreator.getOrderCollectionId(2), 2);
        assertEq(marketCreator.getOrderCurrency(2), address(wgho));
        assertEq(marketCreator.getOrderDetails(2), "encrypted");
        assertEq(marketCreator.getOrderFulfiller(2), fulfiller);
        assertEq(marketCreator.getOrderIsFulfilled(2), false);
        assertEq(
            keccak256(abi.encodePacked(marketCreator.getOrderStatus(2))),
            keccak256(abi.encodePacked(PrintLibrary.OrderStatus.Designing))
        );
        assertEq(marketCreator.getOrderSupply(), 2);
        assertEq(marketCreator.getOrderTotalPrice(2), 0.4 ether);
        assertEq(
            keccak256(abi.encodePacked(marketCreator.getOrderTokenIds(2))),
            keccak256(abi.encodePacked([1, 2]))
        );
        assertEq(
            keccak256(
                abi.encodePacked(marketCreator.getBuyerToOrderIds(buyer))
            ),
            keccak256(abi.encodePacked([1, 2]))
        );

        uint256 _exchangeRate = splitsData.getCurrencyRate(address(wgho));
        uint256 _weiDivisor = splitsData.getCurrencyWei(address(wgho));
        uint256 _tokenAmount = (collectionCreator.getCollectionPrice(2) *
            _weiDivisor) / _exchangeRate;

        assertEq(wgho.balanceOf(designer2), designerBefore + _tokenAmount * 2);
        assertEq(wgho.balanceOf(buyer), buyerBefore - _tokenAmount * 2);
    }

    function testMulti() public {
        testF3M();

        vm.prank(buyer);
        wgho.approve(address(f3mAction), 10 ether);
        vm.prank(buyer);
        mona.approve(address(f3mAction), 10 ether);

        KeyValue[] memory _keysExecute = new KeyValue[](1);
        string[] memory _details = new string[](2);
        address[] memory _currencies = new address[](2);
        uint256[] memory _collectionIds = new uint256[](2);
        uint8[] memory _amounts = new uint8[](2);

        _details[0] = "encrypted";
        _currencies[0] = address(wgho);
        _collectionIds[0] = 2;
        _amounts[0] = 1;

        _details[1] = "";
        _currencies[1] = address(mona);
        _collectionIds[1] = 1;
        _amounts[1] = 4;

  
        _keysExecute[0] = KeyValue({
            key: keccak256("lens.param.buyF3M"),
            value: abi.encode(
                _details,
                _currencies,
                _collectionIds,
                _amounts,
                buyer
            )
        });

        uint256 designerBeforewgho = wgho.balanceOf(designer2);
        uint256 buyerBeforewgho = wgho.balanceOf(buyer);
        uint256 designerBeforemona = mona.balanceOf(designer);
        uint256 buyerBeforemona = mona.balanceOf(buyer);

        vm.prank(actionHub);
        f3mAction.execute(buyer, address(0), 1111, _keysExecute);

        assertEq(
            keccak256(
                abi.encodePacked(
                    collectionCreator.getCollectionMintedTokenIds(1)
                )
            ),
            keccak256(abi.encodePacked([1, 2, 3, 4, 5]))
        );

        assertEq(
            keccak256(
                abi.encodePacked(
                    collectionCreator.getCollectionMintedTokenIds(2)
                )
            ),
            keccak256(abi.encodePacked([1, 2, 3]))
        );
        assertEq(
            chromadinNFT.tokenURI(2),
            "ipfs://QmdxnkW6Ds3Si4kNgVuiC5Z6R6MyLTfPxAK1BcFS6r5VUW"
        );
        assertEq(
            chromadinNFT.tokenURI(3),
            "ipfs://QmdxnkW6Ds3Si4kNgVuiC5Z6R6MyLTfPxAK1BcFS6r5VUW"
        );
        assertEq(
            chromadinNFT.tokenURI(4),
            "ipfs://QmdxnkW6Ds3Si4kNgVuiC5Z6R6MyLTfPxAK1BcFS6r5VUW"
        );
        assertEq(
            chromadinNFT.tokenURI(5),
            "ipfs://QmdxnkW6Ds3Si4kNgVuiC5Z6R6MyLTfPxAK1BcFS6r5VUW"
        );
        assertEq(
            f3mNFT.tokenURI(3),
            "ipfs://QmdxnkW6Ds3Si4kNgVuiC5Z6R6MyLTfPxAK1BcFS6r5VUW"
        );

        assertEq(f3mNFT.getTokenSupply(), 3);
        assertEq(f3mNFT.balanceOf(buyer), 3);
        assertEq(chromadinNFT.getTokenSupply(), 5);
        assertEq(chromadinNFT.balanceOf(buyer), 5);

        assertEq(marketCreator.getOrderAmount(3), 1);
        assertEq(marketCreator.getOrderBuyer(3), buyer);
        assertEq(marketCreator.getOrderCollectionId(3), 2);
        assertEq(marketCreator.getOrderCurrency(3), address(wgho));
        assertEq(marketCreator.getOrderDetails(3), "encrypted");
        assertEq(marketCreator.getOrderFulfiller(3), fulfiller);
        assertEq(marketCreator.getOrderIsFulfilled(3), false);
        assertEq(
            keccak256(abi.encodePacked(marketCreator.getOrderStatus(3))),
            keccak256(abi.encodePacked(PrintLibrary.OrderStatus.Designing))
        );
        assertEq(marketCreator.getOrderSupply(), 4);
        assertEq(marketCreator.getOrderTotalPrice(3), 0.2 ether);
        assertEq(
            keccak256(abi.encodePacked(marketCreator.getOrderTokenIds(3))),
            keccak256(abi.encodePacked([3]))
        );
        assertEq(
            keccak256(
                abi.encodePacked(marketCreator.getBuyerToOrderIds(buyer))
            ),
            keccak256(abi.encodePacked([1, 2, 3, 4]))
        );

        assertEq(marketCreator.getOrderAmount(4), 4);
        assertEq(marketCreator.getOrderBuyer(4), buyer);
        assertEq(marketCreator.getOrderCollectionId(4), 1);
        assertEq(marketCreator.getOrderCurrency(4), address(mona));
        assertEq(marketCreator.getOrderDetails(4), "");
        assertEq(marketCreator.getOrderFulfiller(4), fulfiller);
        assertEq(marketCreator.getOrderIsFulfilled(4), true);
        assertEq(
            keccak256(abi.encodePacked(marketCreator.getOrderStatus(4))),
            keccak256(abi.encodePacked(PrintLibrary.OrderStatus.Fulfilled))
        );
        assertEq(marketCreator.getOrderTotalPrice(4), 4 ether);
        assertEq(
            keccak256(abi.encodePacked(marketCreator.getOrderTokenIds(4))),
            keccak256(abi.encodePacked([2, 3, 4, 5]))
        );

        uint256 _exchangeRate = splitsData.getCurrencyRate(address(wgho));
        uint256 _weiDivisor = splitsData.getCurrencyWei(address(wgho));
        uint256 _tokenAmount = (collectionCreator.getCollectionPrice(2) *
            _weiDivisor) / _exchangeRate;

        assertEq(wgho.balanceOf(designer2), designerBeforewgho + _tokenAmount);
        assertEq(wgho.balanceOf(buyer), buyerBeforewgho - _tokenAmount);

        uint256 _exchangeRate2 = splitsData.getCurrencyRate(address(mona));
        uint256 _weiDivisor2 = splitsData.getCurrencyWei(address(mona));
        uint256 _tokenAmount2 = (collectionCreator.getCollectionPrice(1) *
            _weiDivisor2 *
            4) / _exchangeRate2;

        assertEq(mona.balanceOf(designer), designerBeforemona + _tokenAmount2);
        assertEq(mona.balanceOf(buyer), buyerBeforemona - _tokenAmount2);
    }

    function testCoinOp() public {
        testMulti();

        KeyValue[] memory _keys = new KeyValue[](1);

        PrintLibrary.CollectionInitParams memory params = PrintLibrary
            .CollectionInitParams({
                acceptedTokens: new address[](1),
                uri: "ipfs://multicoin",
                fulfiller: fulfiller,
                price: 6 ether,
                dropId: 2,
                amount: 20,
                printType: 2,
                unlimited: false
            });

        params.acceptedTokens[0] = address(wgho);

        _keys[0] = KeyValue({
            key: keccak256("lens.param.collectionCreator"),
            value: abi.encode(params)
        });

        vm.prank(actionHub);
        coinopAction.configure(designer2, address(0), 14533, _keys);

        assertEq(collectionCreator.getCollectionDesigner(3), designer2);
        assertEq(collectionCreator.getCollectionAmount(3), 20);
        assertEq(collectionCreator.getCollectionFrozen(3), false);
        assertEq(collectionCreator.getCollectionDropId(3), 2);
        assertEq(collectionCreator.getCollectionFulfiller(3), fulfiller);
        assertEq(collectionCreator.getCollectionOrigin(3), 1);
        assertEq(collectionCreator.getCollectionPostId(3), 14533);
        assertEq(collectionCreator.getCollectionPrice(3), 6 ether);
        assertEq(collectionCreator.getCollectionPrintType(3), 2);
        assertEq(collectionCreator.getCollectionSupply(), 3);
        assertEq(collectionCreator.getCollectionUnlimited(3), false);
        assertEq(collectionCreator.getCollectionURI(3), "ipfs://multicoin");

        assertEq(
            keccak256(
                abi.encodePacked(
                    collectionCreator.getCollectionAcceptedTokens(2)
                )
            ),
            keccak256(abi.encodePacked(params.acceptedTokens))
        );
        assertEq(
            collectionCreator.getCollectionMintedTokenIds(3),
            new uint256[](0)
        );
        assertEq(
            keccak256(
                abi.encodePacked(collectionCreator.getDropCollectionIds(2))
            ),
            keccak256(abi.encodePacked([2, 3]))
        );

        vm.prank(admin);
        wgho.transfer(buyer, 100 ether);

        vm.prank(buyer);
        wgho.approve(address(coinopAction), 14 ether);

        KeyValue[] memory _keysExecute = new KeyValue[](1);
        string[] memory _details = new string[](1);
        address[] memory _currencies = new address[](1);
        uint256[] memory _collectionIds = new uint256[](0);
        uint8[] memory _amounts = new uint8[](1);

        _details[0] = "encrypted";
        _currencies[0] = address(wgho);
        _amounts[0] = 2;

        _keysExecute[0] = KeyValue({
            key: keccak256("lens.param.buyCoinop"),
            value: abi.encode(
                _details,
                _currencies,
                _collectionIds,
                _amounts,
                buyer
            )
        });

        uint256 designerBefore = wgho.balanceOf(designer2);
        uint256 buyerBefore = wgho.balanceOf(buyer);

        vm.prank(actionHub);
        coinopAction.execute(buyer, address(0), 14533, _keysExecute);

        assertEq(
            keccak256(
                abi.encodePacked(
                    collectionCreator.getCollectionMintedTokenIds(3)
                )
            ),
            keccak256(abi.encodePacked([1, 2]))
        );
        assertEq(coinopNFT.tokenURI(1), params.uri);
        assertEq(coinopNFT.tokenURI(2), params.uri);
        assertEq(coinopNFT.getTokenSupply(), 2);
        assertEq(coinopNFT.balanceOf(buyer), 2);

        assertEq(marketCreator.getOrderAmount(5), 2);
        assertEq(marketCreator.getOrderBuyer(5), buyer);
        assertEq(marketCreator.getOrderCollectionId(5), 3);
        assertEq(marketCreator.getOrderCurrency(5), address(wgho));
        assertEq(marketCreator.getOrderDetails(5), "encrypted");
        assertEq(marketCreator.getOrderFulfiller(5), fulfiller);
        assertEq(marketCreator.getOrderIsFulfilled(5), false);
        assertEq(
            keccak256(abi.encodePacked(marketCreator.getOrderStatus(5))),
            keccak256(abi.encodePacked(PrintLibrary.OrderStatus.Designing))
        );
        assertEq(marketCreator.getOrderSupply(), 5);
        assertEq(marketCreator.getOrderTotalPrice(5), 12 ether);
        assertEq(
            keccak256(abi.encodePacked(marketCreator.getOrderTokenIds(5))),
            keccak256(abi.encodePacked([1, 2]))
        );
        assertEq(
            keccak256(
                abi.encodePacked(marketCreator.getBuyerToOrderIds(buyer))
            ),
            keccak256(abi.encodePacked([1, 2, 3, 4, 5]))
        );

        uint256 _exchangeRate = splitsData.getCurrencyRate(address(wgho));
        uint256 _weiDivisor = splitsData.getCurrencyWei(address(wgho));
        uint256 _tokenAmount = (collectionCreator.getCollectionPrice(3) *
            _weiDivisor *
            2) / _exchangeRate;

        assertEq(wgho.balanceOf(buyer), buyerBefore - _tokenAmount);

        uint256 _fulfillerBase = splitsData.getFulfillerBase(address(wgho), 2);
        uint256 _fulfillerSplit = splitsData.getFulfillerSplit(
            address(wgho),
            2
        );

        uint256 _calculatedBase = (_fulfillerBase * 2 * _weiDivisor) /
            _exchangeRate;
        uint256 _fulfillerAmount = _calculatedBase +
            ((_fulfillerSplit * _tokenAmount) / 1e20);
     

        assertEq(
            wgho.balanceOf(designer2),
            designerBefore + _tokenAmount - _fulfillerAmount
        );
        assertEq(wgho.balanceOf(fulfiller), _fulfillerAmount);
    }
}
