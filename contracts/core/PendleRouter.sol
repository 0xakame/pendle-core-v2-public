// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";
import "../interfaces/IPActionCore.sol";
import "../interfaces/IPActionYT.sol";
import "../interfaces/IPActionStatic.sol";
import "../interfaces/IPMarketSwapCallback.sol";
import "../periphery/PermissionsV2Upg.sol";

/// @dev this contract will be deployed behind an ERC1967 proxy
/// calls to the ERC1967 proxy will be resolved at this contract, and proxied again to the
/// corresponding implementation contracts

// solhint-disable no-empty-blocks
contract PendleRouter is Proxy, Initializable, UUPSUpgradeable, PermissionsV2Upg {
    address public immutable ACTION_CORE;
    address public immutable ACTION_YT;
    address public immutable ACTION_STATIC;
    address public immutable ACTION_CALLBACK;

    constructor(
        address _ACTION_CORE,
        address _ACTION_YT,
        address _ACTION_CALLBACK,
        address _ACTION_STATIC,
        address _governanceManager
    ) PermissionsV2Upg(_governanceManager) initializer {
        ACTION_CORE = _ACTION_CORE;
        ACTION_YT = _ACTION_YT;
        ACTION_CALLBACK = _ACTION_CALLBACK;
        ACTION_STATIC = _ACTION_STATIC;
    }

    function initialize() external initializer {
        __UUPSUpgradeable_init();
        // no need to initialize PermissionsV2Upg
    }

    function getRouterImplementation(bytes4 sig) public view returns (address) {
        if (
            sig == IPActionCore.mintScyFromRawToken.selector ||
            sig == IPActionCore.redeemScyToRawToken.selector ||
            sig == IPActionCore.mintYoFromRawToken.selector ||
            sig == IPActionCore.redeemYoToRawToken.selector ||
            sig == IPActionCore.addLiquidity.selector ||
            sig == IPActionCore.removeLiquidity.selector ||
            sig == IPActionCore.swapExactOtForScy.selector ||
            sig == IPActionCore.swapOtForExactScy.selector ||
            sig == IPActionCore.swapScyForExactOt.selector ||
            sig == IPActionCore.swapExactScyForOt.selector ||
            sig == IPActionCore.swapExactRawTokenForOt.selector ||
            sig == IPActionCore.swapExactOtForRawToken.selector
        ) {
            return ACTION_CORE;
        } else if (
            sig == IPActionYT.swapExactYtForScy.selector ||
            sig == IPActionYT.swapScyForExactYt.selector ||
            sig == IPActionYT.swapExactScyForYt.selector ||
            sig == IPActionYT.swapExactRawTokenForYt.selector ||
            sig == IPActionYT.swapExactYtForRawToken.selector
        ) {
            return ACTION_YT;
        } else if (sig == IPMarketSwapCallback.swapCallback.selector) {
            return ACTION_CALLBACK;
        }
        /// FROM HERE ONWARDS, ONLY HAVE STATIC & VIEW FUNCTIONS
        else if (
            sig == IPActionStatic.addLiquidityStatic.selector ||
            sig == IPActionStatic.removeLiquidityStatic.selector ||
            sig == IPActionStatic.swapOtForScyStatic.selector ||
            sig == IPActionStatic.swapScyForOtStatic.selector ||
            sig == IPActionStatic.scyIndex.selector ||
            sig == IPActionStatic.getOtImpliedYield.selector ||
            sig == IPActionStatic.getPendleTokenType.selector
        ) {
            return ACTION_STATIC;
        }
        require(false, "invalid market sig");
    }

    function _implementation() internal view override returns (address) {
        return getRouterImplementation(msg.sig);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyGovernance {}
}