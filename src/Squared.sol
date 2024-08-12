// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseHook} from "v4-periphery/BaseHook.sol";

import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/src/types/BeforeSwapDelta.sol";
import {Currency, CurrencyLibrary} from "v4-core/src/types/Currency.sol";
import {SafeCast} from "v4-core/src/libraries/SafeCast.sol";

contract Squared is BaseHook {
    using CurrencyLibrary for Currency;
    using SafeCast for uint256;

    mapping(PoolId => uint256 count) public beforeSwapCount;

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: true, // Prevent v4 liquidity
            afterAddLiquidity: false,
            beforeRemoveLiquidity: true,
            afterRemoveLiquidity: false,
            beforeSwap: true, // Override how swaps are done
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: true, // Allow beforeSwap to return custom delta
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    // -------------------------------------------- //
    //          STATE CHANGING FUNCTIONS
    // -------------------------------------------- //

    function beforeSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata params, bytes calldata)
        external
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        // -------------------------------------------------------------------------------------------- //
        // Example NoOp: if swap is exactInput and the amount is 69e18, then the swap will be skipped   //
        // -------------------------------------------------------------------------------------------- //
        if (params.amountSpecified == -69e18) {
            // take the input token so that v3-swap is skipped...
            uint256 amountTaken = 69e18;
            Currency input = params.zeroForOne ? key.currency0 : key.currency1;
            poolManager.mint(address(this), input.toId(), amountTaken);

            // to NoOp the exact input, we return the amount that's taken by the hook
            // return (BaseHook.beforeSwap.selector, toBeforeSwapDelta(amountTaken.toInt128(), 0), 0);
        }

        // beforeSwapCount[key.toId()]++;
        return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    // function afterSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata, BalanceDelta, bytes calldata)
    //     external
    //     override
    //     returns (bytes4, int128)
    // {
    //     afterSwapCount[key.toId()]++;
    //     return (BaseHook.afterSwap.selector, 0);
    // }

    // function beforeAddLiquidity(
    //     address,
    //     PoolKey calldata key,
    //     IPoolManager.ModifyLiquidityParams calldata,
    //     bytes calldata
    // ) external override returns (bytes4) {
    //     beforeAddLiquidity[key.toId()]++;
    //     return BaseHook.beforeAddLiquidity.selector;
    // }

    // function beforeRemoveLiquidity(
    //     address,
    //     PoolKey calldata key,
    //     IPoolManager.ModifyLiquidityParams calldata,
    //     bytes calldata
    // ) external override returns (bytes4) {
    //     beforeRemoveLiquidity[key.toId()]++;
    //     return BaseHook.beforeRemoveLiquidity.selector;
    // }
}
