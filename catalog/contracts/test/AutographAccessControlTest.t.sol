// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/AutographAccessControl.sol";
import "../src/AutographErrors.sol";

contract AutographAccessControlTest is Test {
    AutographAccessControl accessControl;

    address admin = address(1);
    address nonAdmin = address(2);
    address designer = address(3);
    address actionAddr = address(4);
    address newAdmin = address(5);
    address fulfiller = address(6);

    function setUp() public {
        vm.prank(admin);
        accessControl = new AutographAccessControl();
    }

    function testInitialAdmin() public view {
        assertTrue(
            accessControl.isAdmin(admin),
            "El admin inicial debe ser el desplegador"
        );
        assertEq(accessControl.symbol(), "AAC", "El simbolo debe ser 'AAC'");
        assertEq(
            accessControl.name(),
            "AutographAccessControl",
            "El nombre debe ser 'AutographAccessControl'"
        );
    }

    function testAddAdminSuccess() public {
        vm.prank(admin);
        accessControl.addAdmin(newAdmin);
        assertTrue(
            accessControl.isAdmin(newAdmin),
            "El nuevo admin no se ha anadido correctamente"
        );
    }

    function testAddAdminRevertIfAlreadyAdmin() public {
        vm.prank(admin);
        accessControl.addAdmin(newAdmin);
        vm.prank(admin);
        vm.expectRevert(AutographErrors.Existing.selector);
        accessControl.addAdmin(newAdmin);
    }

    function testAddAdminRevertIfAddingSelf() public {
        vm.prank(admin);
        vm.expectRevert(AutographErrors.Existing.selector);
        accessControl.addAdmin(admin);
    }

    function testRemoveAdminSuccess() public {
        vm.prank(admin);
        accessControl.addAdmin(newAdmin);
        vm.prank(admin);
        accessControl.removeAdmin(newAdmin);
        assertFalse(
            accessControl.isAdmin(newAdmin),
            "El admin no se ha removido correctamente"
        );
    }

    function testRemoveAdminRevertIfNotAdmin() public {
        vm.prank(admin);
        vm.expectRevert(AutographErrors.AddressInvalid.selector);
        accessControl.removeAdmin(newAdmin);
    }

    function testRemoveAdminRevertIfRemovingSelf() public {
        vm.prank(admin);
        vm.expectRevert(AutographErrors.CantRemoveSelf.selector);
        accessControl.removeAdmin(admin);
    }

    function testAddDesignerSuccess() public {
        vm.prank(admin);
        accessControl.addDesigner(designer);
        assertTrue(
            accessControl.isDesigner(designer),
            "El disenador no se ha anadido correctamente"
        );
    }

    function testAddDesignerRevertIfExisting() public {
        vm.prank(admin);
        accessControl.addDesigner(designer);
        vm.prank(admin);
        vm.expectRevert(AutographErrors.Existing.selector);
        accessControl.addDesigner(designer);
    }

    function testRemoveDesignerSuccess() public {
        vm.prank(admin);
        accessControl.addDesigner(designer);
        vm.prank(admin);
        accessControl.removeDesigner(designer);
        assertFalse(
            accessControl.isDesigner(designer),
            "El disenador no se ha removido correctamente"
        );
    }

    function testRemoveDesignerRevertIfNotExisting() public {
        vm.prank(admin);
        vm.expectRevert(AutographErrors.AddressInvalid.selector);
        accessControl.removeDesigner(designer);
    }

    function testAddActionSuccess() public {
        vm.prank(admin);
        accessControl.addAction(actionAddr);
        assertTrue(
            accessControl.isAction(actionAddr),
            "La accion no se ha anadido correctamente"
        );
    }

    function testAddActionRevertIfExisting() public {
        vm.prank(admin);
        accessControl.addAction(actionAddr);
        vm.prank(admin);
        vm.expectRevert(AutographErrors.Existing.selector);
        accessControl.addAction(actionAddr);
    }

    function testRemoveActionSuccess() public {
        vm.prank(admin);
        accessControl.addAction(actionAddr);
        vm.prank(admin);
        accessControl.removeOpenAction(actionAddr);
        assertFalse(
            accessControl.isAction(actionAddr),
            "La accion no se ha removido correctamente"
        );
    }

    function testRemoveActionRevertIfNotExisting() public {
        vm.prank(admin);
        vm.expectRevert(AutographErrors.AddressInvalid.selector);
        accessControl.removeOpenAction(actionAddr);
    }

    function testOnlyAdminRestriction() public {
        vm.prank(nonAdmin);
        vm.expectRevert(AutographErrors.AddressInvalid.selector);
        accessControl.addAdmin(newAdmin);

        vm.prank(nonAdmin);
        vm.expectRevert(AutographErrors.AddressInvalid.selector);
        accessControl.addDesigner(designer);

        vm.prank(nonAdmin);
        vm.expectRevert(AutographErrors.AddressInvalid.selector);
        accessControl.addAction(actionAddr);
    }

    function testFulfiller() public {
        vm.prank(admin);
        accessControl.setFulfiller(fulfiller);

        vm.prank(nonAdmin);
        vm.expectRevert(AutographErrors.AddressInvalid.selector);
        accessControl.setFulfiller(fulfiller);

        assertEq(
            accessControl.fulfiller(),
            fulfiller,
            "El fulfiller inicial debe ser address(0)"
        );
    }
}
