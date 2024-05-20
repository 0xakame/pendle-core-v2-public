// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../../SYBaseUpg.sol";
import "../../../../interfaces/IERC4626.sol";
import "../../../../interfaces/Karak/IKarakVault.sol";
import "../../../../interfaces/Karak/IKarakVaultSupervisor.sol";

abstract contract PendleKarakVaultSYBaseUpg is SYBaseUpg {
    using ArrayLib for address[];

    error KarakVaultAssetLimitExceeded(uint256 assetLimit, uint256 totalAsset, uint256 amountAssetToDeposit);

    // solhint-disable immutable-vars-naming
    address public immutable vault; // vault is also share token
    address public immutable stakeToken;
    address public immutable vaultSupervisor;

    // address public immutable shareToken;

    constructor(address _vault, address _vaultSupervisor) SYBaseUpg(IERC4626(_vault).asset()) {
        vault = _vault;
        stakeToken = IERC4626(_vault).asset();
        vaultSupervisor = _vaultSupervisor;
    }

    /*///////////////////////////////////////////////////////////////
                    Karak Vault Initialization
    //////////////////////////////////////////////////////////////*/

    function __KarakVaultSY_init() internal {
        _safeApproveInf(stakeToken, vault);
    }

    /*///////////////////////////////////////////////////////////////
                    DEPOSIT/REDEEM USING BASE TOKENS
    //////////////////////////////////////////////////////////////*/

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn != stakeToken && tokenIn != vault) {
            (tokenIn, amountDeposited) = (stakeToken, _wrapToStakeToken(tokenIn, amountDeposited));
        }

        if (tokenIn == stakeToken) {
            // return IKarakVaultSupervisor
            return IKarakVaultSupervisor(vaultSupervisor).deposit(vault, amountDeposited, 0);
        } else {
            IKarakVaultSupervisor(vaultSupervisor).returnShares(vault, amountDeposited);
            return amountDeposited;
        }
    }

    function _redeem(
        address receiver,
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal virtual override returns (uint256 /*amountTokenOut*/) {
        IKarakVaultSupervisor(vaultSupervisor).returnShares(vault, amountSharesToRedeem);
        _transferOut(vault, receiver, amountSharesToRedeem);
        return amountSharesToRedeem;
    }

    /*///////////////////////////////////////////////////////////////
                MISC FUNCTIONS FOR METADATA
    //////////////////////////////////////////////////////////////*/

    function _previewDeposit(address tokenIn, uint256 amountTokenToDeposit) internal view override returns (uint256) {
        if (tokenIn != stakeToken && tokenIn != vault) {
            (tokenIn, amountTokenToDeposit) = (stakeToken, _previewToStakeToken(tokenIn, amountTokenToDeposit));
        }

        if (tokenIn == stakeToken) {
            uint256 totalAsset = IERC4626(vault).totalAssets();
            uint256 assetLimit = IKarakVault(vault).assetLimit();
            if (totalAsset + amountTokenToDeposit > assetLimit) {
                revert KarakVaultAssetLimitExceeded(assetLimit, totalAsset, amountTokenToDeposit);
            }

            return amountTokenToDeposit;
        }
        return _previewToStakeToken(tokenIn, amountTokenToDeposit);
    }

    function _previewRedeem(
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal pure override returns (uint256 /*amountTokenOut*/) {
        return amountSharesToRedeem;
    }

    function getTokensIn() public view virtual override returns (address[] memory) {
        return ArrayLib.create(vault, stakeToken).merge(_getAdditionalTokens());
    }

    function getTokensOut() public view virtual override returns (address[] memory) {
        return ArrayLib.create(vault);
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return token == vault || token == stakeToken || _canWrapToStakeToken(token);
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == vault;
    }

    /*///////////////////////////////////////////////////////////////
                    ADDITIONAL TOKEN IN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _getAdditionalTokens() internal view virtual returns (address[] memory) {}

    function _previewToStakeToken(address, uint256) internal view virtual returns (uint256) {
        assert(false);
    }

    function _wrapToStakeToken(address, uint256) internal virtual returns (uint256) {
        assert(false);
    }

    function _canWrapToStakeToken(address) internal view virtual returns (bool) {
        return false;
    }
}