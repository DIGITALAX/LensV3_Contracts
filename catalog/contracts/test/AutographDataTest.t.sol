// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/AutographData.sol";
import "../src/AutographNFT.sol";
import "../src/AutographAccessControl.sol";
import "../src/AutographLibrary.sol";
import "../src/AutographCollections.sol";
import "../src/AutographCatalog.sol";
import "../src/CatalogNFT.sol";
import "../src/TestERC20.sol";
import "../src/AutographAction.sol";
import "../src/skyhunters/SkyhuntersAccessControls.sol";

contract AutographDataTest is Test {
    AutographData public autographData;
    AutographAccessControl public accessControl;
    AutographCollections public autographCollections;
    AutographMarket public autographMarket;
    AutographCatalog public autographCatalog;
    AutographNFT public autographNFT;
    CatalogNFT public catalogNFT;
    AutographAction public autographAction;
    SkyhuntersAccessControls skyhunters;
    TestERC20 public mona;
    TestERC20 public usdt;
    TestERC20 public eth;
    TestERC20 public matic;

    address public owner = address(1);
    address public hub = address(111);
    address public nonAdmin = address(2);
    address public designer = address(8);
    address public secondDesigner = address(11);
    address public buyer = address(12);
    address public fulfiller = address(13);
    address public npc1 = address(14);
    address public npc2 = address(15);
    address public npc3 = address(16);
    address public npc4 = address(17);

    bytes32 constant ADDRESS_NOT_VERIFIED_ERROR =
        keccak256("AddressNotVerified()");
    bytes32 constant ADDRESS_INVALID_ERROR = keccak256("InvalidAddress()");
    bytes32 constant EXCEED_AMOUNT_ERROR = keccak256("ExceedAmount()");
    bytes32 constant COLLECTION_NOT_FOUND_ERROR =
        keccak256("CollectionNotFound()");

    function setUp() public {
        accessControl = new AutographAccessControl();
        skyhunters = new SkyhuntersAccessControls();
        autographNFT = new AutographNFT(address(accessControl));
        catalogNFT = new CatalogNFT(address(accessControl));
        autographCatalog = new AutographCatalog(
            address(accessControl),
            address(catalogNFT)
        );
        autographData = new AutographData(address(accessControl));
        autographCollections = new AutographCollections(
            address(accessControl),
            payable(address(skyhunters))
        );
        autographMarket = new AutographMarket(
            address(accessControl),
            address(autographCatalog),
            address(autographCollections),
            address(autographNFT),
            address(catalogNFT),
            address(autographData)
        );

        autographAction = new AutographAction(
            hub,
            address(accessControl),
            address(autographCollections),
            address(autographMarket),
            address(autographCatalog)
        );
        eth = new TestERC20();
        mona = new TestERC20();
        usdt = new TestERC20();
        matic = new TestERC20();

        autographData.setShirtBase(50000000000000000000);
        autographData.setHoodieBase(60000000000000000000);
        autographData.setVig(5);

        autographCollections.setAutographData(address(autographData));
        autographCollections.setAutographMarket(address(autographMarket));

        autographMarket.setAutographCollections(address(autographCollections));
        autographMarket.setAutographData(address(autographData));

        autographNFT.setAutographCollections(address(autographCollections));
        autographNFT.setAutographMarket(address(autographMarket));

        catalogNFT.setAutographCatalog(address(autographCatalog));
        catalogNFT.setAutographMarket(address(autographMarket));

        skyhunters.addAgent(npc1);
        skyhunters.addAgent(npc2);
        skyhunters.addAgent(npc3);
        skyhunters.addAgent(npc4);

        autographData.addCurrency(
            address(matic),
            1000000000000000000,
            772200000000000000
        );
        autographData.addCurrency(
            address(mona),
            1000000000000000000,
            411150300000000000000
        );
        autographData.addCurrency(
            address(eth),
            1000000000000000000,
            2077490000000000000000
        );
        autographData.addCurrency(address(usdt), 1000000, 1000000000000000000);

        vm.prank(address(this));
        accessControl.addAdmin(owner);

        vm.prank(owner);
        accessControl.addAction(address(autographAction));

        vm.prank(owner);
        accessControl.addDesigner(designer);

        vm.prank(owner);
        accessControl.addDesigner(secondDesigner);

        vm.prank(owner);
        accessControl.setFulfiller(fulfiller);
    }

    function testCreateAutograph() public {
        address[] memory acceptedTokens = new address[](3);
        acceptedTokens[0] = address(eth);
        acceptedTokens[1] = address(usdt);
        acceptedTokens[2] = address(matic);
        string[] memory pages = new string[](4);
        pages[0] = "page1uri";
        pages[1] = "page2uri";
        pages[2] = "page3uri";
        pages[3] = "page4uri";

        AutographLibrary.ActionParams memory params = AutographLibrary
            .ActionParams({
                autographType: AutographLibrary.AutographType.Catalog,
                price: 100000000000000000000,
                acceptedTokens: acceptedTokens,
                uri: "mainuri",
                amount: 500,
                pages: pages,
                pageCount: 4,
                collectionId: 0
            });

        KeyValue[] memory params_config = new KeyValue[](1);

        params_config[0] = KeyValue({
            key: bytes32(abi.encodePacked("autographCreator")),
            value: abi.encode(params)
        });

        vm.prank(owner);
        autographAction.configure(owner, address(0), 120, params_config);

        assertEq(autographCatalog.getAutographAmount(), 500);
        assertEq(autographCatalog.getAutographPrice(), 100000000000000000000);
        assertEq(autographCatalog.getAutographURI(), "mainuri");
        assertEq(autographCatalog.getAutographPageCount(), 4);
        assertEq(autographCatalog.getAutographPage(1), "page1uri");
        assertEq(autographCatalog.getAutographPage(2), "page2uri");
        assertEq(autographCatalog.getAutographPage(3), "page3uri");
        assertEq(autographCatalog.getAutographPage(4), "page4uri");
        assertEq(autographCatalog.getAutographAcceptedTokens(), acceptedTokens);
        assertEq(autographCatalog.getAutographDesigner(), owner);
        assertEq(autographCatalog.getAutographPostId(), 120);
    }

    function createInitialGalleryAndCollections()
        internal
        returns (AutographLibrary.CollectionInit[] memory)
    {
        string[] memory uris = new string[](4);
        uris[0] = "collectiononeuri";
        uris[1] = "collectiontwouri";
        uris[2] = "collectionthreeuri";
        uris[3] = "collectionfoururi";

        uint8[] memory amounts = new uint8[](4);
        amounts[0] = 10;
        amounts[1] = 1;
        amounts[2] = 7;
        amounts[3] = 20;

        uint256[] memory prices = new uint256[](4);
        prices[0] = 100000000000000000000;
        prices[1] = 180000000000000000000;
        prices[2] = 200000000000000000000;
        prices[3] = 300000000000000000000;

        address[][] memory acceptedTokens = new address[][](4);
        acceptedTokens[0] = new address[](3);
        acceptedTokens[0][0] = address(mona);
        acceptedTokens[0][1] = address(eth);
        acceptedTokens[0][2] = address(usdt);
        acceptedTokens[1] = new address[](2);
        acceptedTokens[1][0] = address(mona);
        acceptedTokens[1][1] = address(usdt);
        acceptedTokens[2] = new address[](2);
        acceptedTokens[2][0] = address(matic);
        acceptedTokens[2][1] = address(usdt);
        acceptedTokens[3] = new address[](3);
        acceptedTokens[3][0] = address(mona);
        acceptedTokens[3][1] = address(eth);
        acceptedTokens[3][2] = address(usdt);

        AutographLibrary.AutographType[]
            memory collectionTypes = new AutographLibrary.AutographType[](4);
        collectionTypes[0] = AutographLibrary.AutographType.Hoodie;
        collectionTypes[1] = AutographLibrary.AutographType.NFT;
        collectionTypes[2] = AutographLibrary.AutographType.NFT;
        collectionTypes[3] = AutographLibrary.AutographType.Shirt;

        address[][] memory npcs = new address[][](4);
        npcs[0] = new address[](1);
        npcs[0][0] = npc1;
        npcs[1] = new address[](1);
        npcs[1][0] = npc2;
        npcs[2] = new address[](1);
        npcs[2][0] = npc3;
        npcs[3] = new address[](1);
        npcs[3][0] = npc4;

        AutographLibrary.CollectionInit[]
            memory colls = new AutographLibrary.CollectionInit[](4);

        for (uint256 i = 0; i < 4; i++) {
            colls[i] = AutographLibrary.CollectionInit({
                uri: uris[i],
                amount: amounts[i],
                price: prices[i],
                acceptedTokens: acceptedTokens[i],
                collectionType: collectionTypes[i],
                npcs: npcs[i]
            });
        }

        vm.prank(designer);
        autographCollections.createGallery(colls, "galleryURI");

        vm.prank(owner);
        try autographCollections.createGallery(colls, "galleryURI") {
            fail();
        } catch (bytes memory lowLevelData) {
            bytes4 errorSelector = bytes4(lowLevelData);
            assertEq(errorSelector, bytes4(ADDRESS_NOT_VERIFIED_ERROR));
        }

        return colls;
    }

    function testCreateGalleryOne() public {
        AutographLibrary.CollectionInit[]
            memory _params = createInitialGalleryAndCollections();

        uint16[] memory galleriesExpected = new uint16[](1);
        galleriesExpected[0] = 1;

        assertEq(autographCollections.getGalleryCounter(), 1);
        assertEq(autographCollections.getCollectionCounter(), 4);
        assertEq(autographCollections.getDesignerGalleries(designer).length, 1);
        assertEq(
            keccak256(
                abi.encodePacked(
                    (autographCollections.getDesignerGalleries(designer))
                )
            ),
            keccak256(abi.encodePacked((galleriesExpected)))
        );
        assertEq(autographCollections.getCollectionDesigner(1), designer);
        assertEq(autographCollections.getCollectionURI(1), _params[0].uri);
        assertEq(autographCollections.getCollectionURI(2), _params[1].uri);
    }

    function testCreateGalleryTwo() public {
        AutographLibrary.CollectionInit[]
            memory _params = createInitialGalleryAndCollections();

        assertEq(
            autographCollections.getCollectionAmount(1),
            _params[0].amount
        );
        assertEq(
            autographCollections.getCollectionAmount(3),
            _params[2].amount
        );
        assertEq(autographCollections.getCollectionPrice(1), _params[0].price);
        assertEq(autographCollections.getCollectionPrice(2), _params[1].price);
        assertEq(
            autographCollections.getCollectionAcceptedTokens(1),
            _params[0].acceptedTokens
        );
        assertEq(
            autographCollections.getCollectionAcceptedTokens(2),
            _params[1].acceptedTokens
        );
        assertEq(
            autographCollections.getCollectionIsAcceptedToken(address(eth), 1),
            true
        );
        assertEq(
            autographCollections.getCollectionIsAcceptedToken(address(eth), 3),
            false
        );
    }

    function testCreateGalleryThree() public {
        createInitialGalleryAndCollections();

        uint256[] memory collsExpected = new uint256[](4);
        collsExpected[0] = 1;
        collsExpected[1] = 2;
        collsExpected[2] = 3;
        collsExpected[3] = 4;

        assertEq(
            autographCollections.getGalleryCollectionIds(1),
            collsExpected
        );
        assertEq(autographCollections.getCollectionGallery(1), 1);
        assertEq(autographCollections.getCollectionGallery(3), 1);
        assertEq(autographCollections.getCollectionMintedTokenIds(1).length, 0);
    }

    function testAddPubProfileCollection() public {
        createInitialGalleryAndCollections();

        AutographLibrary.ActionParams memory params = AutographLibrary
            .ActionParams({
                autographType: AutographLibrary.AutographType.NFT,
                price: 0,
                acceptedTokens: new address[](0),
                uri: "",
                amount: 0,
                pages: new string[](0),
                pageCount: 0,
                collectionId: 1
            });

        KeyValue[] memory params_config = new KeyValue[](1);

        params_config[0] = KeyValue({
            key: bytes32(abi.encodePacked("autographCreator")),
            value: abi.encode(params)
        });
        autographAction.configure(owner, address(0), 450, params_config);

        AutographLibrary.ActionParams memory paramsTwo = AutographLibrary
            .ActionParams({
                autographType: AutographLibrary.AutographType.Catalog,
                price: 0,
                acceptedTokens: new address[](0),
                uri: "",
                amount: 0,
                pages: new string[](0),
                pageCount: 0,
                collectionId: 4
            });

        KeyValue[] memory params_config1 = new KeyValue[](1);

        params_config1[0] = KeyValue({
            key: bytes32(abi.encodePacked("autographCreator")),
            value: abi.encode(paramsTwo)
        });
        autographAction.configure(owner, address(0), 1523, params_config1);

        assertEq(autographCollections.getCollectionByPostId(450), 1);
        assertEq(autographCollections.getCollectionPostIds(1)[0], 450);
        assertEq(autographCatalog.getAutographPostId(), 1523);
    }

    function testAddAndDeleteCollectionGallery() public {
        AutographLibrary.CollectionInit[]
            memory _params = createInitialGalleryAndCollections();

        vm.prank(designer);
        autographCollections.addCollections(_params, 1);

        uint256[] memory colls = autographCollections.getGalleryCollectionIds(
            1
        );
        assertEq(colls.length, 8);

        vm.prank(designer);
        autographCollections.deleteCollection(3);

        colls = autographCollections.getGalleryCollectionIds(1);
        assertEq(colls.length, 7);

        vm.prank(designer);
        autographCollections.deleteCollection(7);

        colls = autographCollections.getGalleryCollectionIds(1);
        assertEq(colls.length, 6);

        vm.prank(owner);
        try autographCollections.addCollections(_params, 1) {
            fail();
        } catch (bytes memory lowLevelData) {
            bytes4 errorSelector = bytes4(lowLevelData);
            assertEq(errorSelector, bytes4(ADDRESS_NOT_VERIFIED_ERROR));
        }

        vm.prank(secondDesigner);
        try autographCollections.deleteCollection(3) {
            fail();
        } catch (bytes memory lowLevelData) {
            bytes4 errorSelector = bytes4(lowLevelData);
            assertEq(errorSelector, bytes4(COLLECTION_NOT_FOUND_ERROR));
        }

        vm.prank(designer);
        autographCollections.deleteGallery(1);

        colls = autographCollections.getGalleryCollectionIds(1);
        assertEq(colls.length, 0);

        createInitialGalleryAndCollections();

        colls = autographCollections.getGalleryCollectionIds(2);
        assertEq(colls.length, 4);
    }

    function testCatalogPurchaseOpenAction() public {
        address[] memory acceptedTokens = new address[](3);
        acceptedTokens[0] = address(eth);
        acceptedTokens[1] = address(usdt);
        acceptedTokens[2] = address(matic);
        string[] memory pages = new string[](4);
        pages[0] = "page1uri";
        pages[1] = "page2uri";
        pages[2] = "page3uri";
        pages[3] = "page4uri";

        AutographLibrary.ActionParams memory params = AutographLibrary
            .ActionParams({
                autographType: AutographLibrary.AutographType.Catalog,
                price: 100000000000000000000,
                acceptedTokens: acceptedTokens,
                uri: "mainuri",
                amount: 500,
                pages: pages,
                pageCount: 4,
                collectionId: 0
            });

        KeyValue[] memory params_config = new KeyValue[](1);

        params_config[0] = KeyValue({
            key: bytes32(abi.encodePacked("autographCreator")),
            value: abi.encode(params)
        });

        autographAction.configure(owner, address(0), 120, params_config);

        eth.transfer(buyer, 96270018146898420);
        vm.startPrank(buyer);
        eth.approve(address(autographMarket), 96270018146898420);

        KeyValue[] memory params_execute = new KeyValue[](3);

        params_execute[0] = KeyValue({
            key: bytes32(abi.encodePacked("encryptedFulfillment")),
            value: abi.encode("encryptedForCatalog")
        });

        params_execute[1] = KeyValue({
            key: bytes32(abi.encodePacked("currency")),
            value: abi.encode(address(eth))
        });

        params_execute[2] = KeyValue({
            key: bytes32(abi.encodePacked("quantity")),
            value: abi.encode(uint256(2))
        });

        autographAction.execute(buyer, address(0), 120, params_execute);

        assertEq(autographMarket.getOrderCounter(), 1);
        assertEq(autographMarket.getOrderBuyer(1), buyer);
        assertEq(
            keccak256(
                abi.encodePacked((autographMarket.getBuyerOrderIds(buyer)))
            ),
            keccak256(abi.encodePacked([1]))
        );
        assertEq(autographMarket.getOrderTotal(1), 200000000000000000000);
        assertEq(autographMarket.getOrderFulfillment(1), "encryptedForCatalog");
        assertEq(
            keccak256(
                abi.encodePacked((autographMarket.getOrderSubOrderIds(1)))
            ),
            keccak256(abi.encodePacked(([1])))
        );
        assertEq(autographMarket.getSubOrderAmount(1), 2);
        assertEq(autographMarket.getSubOrderTotal(1), 200000000000000000000);
        assertEq(autographMarket.getSubOrderCollectionId(1), 0);
        assertEq(autographMarket.getSubOrderCurrency(1), address(eth));
        assertEq(
            keccak256(
                abi.encodePacked((autographMarket.getSubOrderTokensMinted(1)))
            ),
            keccak256(abi.encodePacked(([1, 2])))
        );
    }

    function testCollectionNFTPurchaseOpenAction() public {
        createInitialGalleryAndCollections();
        AutographLibrary.ActionParams memory params = AutographLibrary
            .ActionParams({
                autographType: AutographLibrary.AutographType.NFT,
                price: 0,
                acceptedTokens: new address[](0),
                uri: "",
                amount: 0,
                pages: new string[](0),
                pageCount: 0,
                collectionId: 3
            });

        KeyValue[] memory params_config = new KeyValue[](1);

        params_config[0] = KeyValue({
            key: bytes32(abi.encodePacked("autographCreator")),
            value: abi.encode(params)
        });
        autographAction.configure(owner, address(0), 532, params_config);

        params = AutographLibrary.ActionParams({
            autographType: AutographLibrary.AutographType.NFT,
            price: 0,
            acceptedTokens: new address[](0),
            uri: "",
            amount: 0,
            pages: new string[](0),
            pageCount: 0,
            collectionId: 2
        });

        KeyValue[] memory params_config1 = new KeyValue[](1);

        params_config1[0] = KeyValue({
            key: bytes32(abi.encodePacked("autographCreator")),
            value: abi.encode(params)
        });

        autographAction.configure(owner, address(0), 600, params_config1);

        matic.transfer(buyer, 259000259000259000259);
        vm.prank(buyer);
        matic.approve(address(autographMarket), 259000259000259000259);

        KeyValue[] memory params_execute = new KeyValue[](3);

        params_execute[0] = KeyValue({
            key: bytes32(abi.encodePacked("encryptedFulfillment")),
            value: abi.encode("encryptedForCollectionNFT")
        });

        params_execute[1] = KeyValue({
            key: bytes32(abi.encodePacked("currency")),
            value: abi.encode(address(matic))
        });

        params_execute[2] = KeyValue({
            key: bytes32(abi.encodePacked("quantity")),
            value: abi.encode(uint256(1))
        });

        vm.prank(buyer);
        autographAction.execute(buyer, address(0), 532, params_execute);

        assertEq(autographMarket.getOrderCounter(), 1);
        assertEq(autographMarket.getOrderBuyer(1), buyer);
        assertEq(
            keccak256(
                abi.encodePacked((autographMarket.getBuyerOrderIds(buyer)))
            ),
            keccak256(abi.encodePacked([1]))
        );
        assertEq(autographMarket.getOrderTotal(1), 200000000000000000000);
        assertEq(
            autographMarket.getOrderFulfillment(1),
            "encryptedForCollectionNFT"
        );
        assertEq(
            keccak256(abi.encodePacked((autographMarket.getSubOrderType(1)))),
            keccak256(abi.encodePacked((AutographLibrary.AutographType.NFT)))
        );
        assertEq(autographMarket.getSubOrderAmount(1), 1);
        assertEq(autographMarket.getSubOrderTotal(1), 200000000000000000000);
        assertEq(
            keccak256(
                abi.encodePacked((autographMarket.getSubOrderTokensMinted(1)))
            ),
            keccak256(abi.encodePacked(([1])))
        );
        assertEq(autographMarket.getSubOrderCurrency(1), address(matic));
        assertEq(
            keccak256(
                abi.encodePacked((autographMarket.getSubOrderTokensMinted(1)))
            ),
            keccak256(abi.encodePacked(([1])))
        );

        usdt.transfer(buyer, 259000259000259000259);
        vm.prank(buyer);
        usdt.approve(address(autographMarket), 259000259000259000259);

        KeyValue[] memory params_execute1 = new KeyValue[](3);

        params_execute1[0] = KeyValue({
            key: bytes32(abi.encodePacked("encryptedFulfillment")),
            value: abi.encode("encryptedForCollectionNFT")
        });

        params_execute1[1] = KeyValue({
            key: bytes32(abi.encodePacked("currency")),
            value: abi.encode(address(usdt))
        });

        params_execute1[2] = KeyValue({
            key: bytes32(abi.encodePacked("quantity")),
            value: abi.encode(uint256(2))
        });

        vm.prank(buyer);
        try autographAction.execute(buyer, address(0), 600, params_execute1) {
            fail();
        } catch (bytes memory lowLevelData) {
            bytes4 errorSelector = bytes4(lowLevelData);
            assertEq(errorSelector, bytes4(EXCEED_AMOUNT_ERROR));
        }
    }

    function testCollectionPrintPurchaseOpenAction() public {
        createInitialGalleryAndCollections();

        usdt.transfer(buyer, 259000259000259000259);
        vm.prank(buyer);
        usdt.approve(address(autographMarket), 259000259000259000259);

        AutographLibrary.ActionParams memory params = AutographLibrary
            .ActionParams({
                autographType: AutographLibrary.AutographType.Hoodie,
                price: 0,
                acceptedTokens: new address[](0),
                uri: "",
                amount: 0,
                pages: new string[](0),
                pageCount: 0,
                collectionId: 1
            });

        KeyValue[] memory params_config = new KeyValue[](1);

        params_config[0] = KeyValue({
            key: bytes32(abi.encodePacked("autographCreator")),
            value: abi.encode(params)
        });
        autographAction.configure(owner, address(0), 123333, params_config);

        KeyValue[] memory params_execute = new KeyValue[](3);

        params_execute[0] = KeyValue({
            key: bytes32(abi.encodePacked("encryptedFulfillment")),
            value: abi.encode("encryptedForCollectionHoodie")
        });

        params_execute[1] = KeyValue({
            key: bytes32(abi.encodePacked("currency")),
            value: abi.encode(address(usdt))
        });

        params_execute[2] = KeyValue({
            key: bytes32(abi.encodePacked("quantity")),
            value: abi.encode(uint256(1))
        });

        vm.prank(buyer);
        autographAction.execute(buyer, address(0), 123333, params_execute);
    }

    function testCatalogCollectionPurchase() public {
        createInitialGalleryAndCollections();

        address[] memory acceptedTokens = new address[](3);
        acceptedTokens[0] = address(eth);
        acceptedTokens[1] = address(usdt);
        acceptedTokens[2] = address(mona);
        string[] memory pages = new string[](4);
        pages[0] = "page1uri";
        pages[1] = "page2uri";
        pages[2] = "page3uri";
        pages[3] = "page4uri";

        AutographLibrary.ActionParams memory params = AutographLibrary
            .ActionParams({
                autographType: AutographLibrary.AutographType.Catalog,
                price: 100000000000000000000,
                acceptedTokens: acceptedTokens,
                uri: "mainuri",
                amount: 500,
                pages: pages,
                pageCount: 4,
                collectionId: 0
            });

        KeyValue[] memory params_config = new KeyValue[](1);

        params_config[0] = KeyValue({
            key: bytes32(abi.encodePacked("autographCreator")),
            value: abi.encode(params)
        });
        autographAction.configure(owner, address(0), 120, params_config);

        eth.transfer(buyer, 298810054000000000);
        vm.prank(buyer);
        eth.approve(address(autographMarket), 298810054000000000);

        mona.transfer(buyer, 972880234000000000);
        vm.prank(buyer);
        mona.approve(address(autographMarket), 972880234000000000);

        address[] memory currencies = new address[](2);
        currencies[0] = address(mona);
        currencies[1] = address(eth);
        uint256[] memory collectionIds = new uint256[](2);
        collectionIds[0] = 0;
        collectionIds[1] = 4;

        uint8[] memory quantities = new uint8[](2);
        quantities[0] = 4;
        quantities[1] = 2;
        uint256 designerBalanceEth = eth.balanceOf(designer);
        uint256 buyerBalanceEth = eth.balanceOf(buyer);
        uint256 buyerBalanceMona = mona.balanceOf(buyer);
        vm.prank(buyer);
        autographMarket.buyTokens(
            currencies,
            collectionIds,
            quantities,
            "fulfillment here"
        );

        assertEq(
            eth.balanceOf(designer),
            designerBalanceEth + 228641293098883749
        );
        assertEq(eth.balanceOf(fulfiller), 60168761341811512);
        assertEq(eth.balanceOf(buyer), buyerBalanceEth - 288810054440695261);
        assertEq(mona.balanceOf(buyer), buyerBalanceMona - 972880233822035396);
        assertEq(autographCatalog.getAutographMinted(), 4);
        assertEq(
            keccak256(
                abi.encodePacked((autographMarket.getSubOrderTokensMinted(2)))
            ),
            keccak256(abi.encodePacked(([1, 2])))
        );
    }
}
