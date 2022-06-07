// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

abstract contract ActionType {
    enum ACTION_TYPE {
        SwapExactYtForScy,
        SwapSCYForExactYt,
        SwapExactScyForYt,
        SwapYtForExactScy
    }
}
