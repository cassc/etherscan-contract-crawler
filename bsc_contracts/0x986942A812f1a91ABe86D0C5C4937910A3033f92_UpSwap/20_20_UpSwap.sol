// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "contracts/interfaces/IOpenOceanCaller.sol";
import "contracts/interfaces/IOpenOceanExchange.sol";
import "contracts/interfaces/IUpSingleToken.sol";
import "contracts/interfaces/IUpLPToken.sol";
import "contracts/interfaces/IUpSwapPair.sol";
import "contracts/interfaces/IUpSwapRouter02.sol";
import "contracts/interfaces/IUpSwapFactory.sol";
import "contracts/interfaces/IAdapter.sol";

import "contracts/libraries/UniversalERC20.sol";

contract UpSwap is Pausable, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using UniversalERC20 for IERC20;

    // OpenOcean exchange interface
    IOpenOceanExchange public openOcean;

    // UpSwap router address 
    IUpSwapRouter02 public router;

    // UpSwap factory address 
    IUpSwapFactory public factory;

    // Adapter contract address
    IAdapter public adapter;

    /// @dev modifier to evaluate zero address
    modifier nonZeroAddr(address _addr) {
        require(_addr != address(0), "Zero address");
        _;
    }

    constructor(address _openOceanAddr, address _router, address _factory, address _adapter) nonZeroAddr(_openOceanAddr) nonZeroAddr(_router) nonZeroAddr(_factory) nonZeroAddr(_adapter) {
        openOcean = IOpenOceanExchange(_openOceanAddr);
        router = IUpSwapRouter02(_router);
        factory = IUpSwapFactory(_factory);
        adapter = IAdapter(_adapter);
    }

    /// @dev perform swapping via OpenOcean exchange aggregator
    function swapWithNonUnderlying(IOpenOceanCaller caller, IOpenOceanExchange.SwapDescription calldata desc, IOpenOceanCaller.CallDescription[] calldata calls, address upAddr, bool buyUp, bool sellUp, uint256 sellUpAmt) external payable whenNotPaused returns (uint256 returnAmt) {
        require(msg.value == (desc.srcToken.isETH() ? desc.amount : 0), "Invalid msg.value");
        require(desc.dstReceiver != address(0), "Zero address");
        require(desc.srcToken != desc.dstToken, "Same token address");
        require(!(buyUp == true && sellUp == true), "Invalid buyUp and sellUp");

        if (buyUp == false && sellUp == false) {
            require(upAddr == address(0), "Non zero address");
            require(desc.dstReceiver != address(this), "Invalid dstReceiver address");
            require(sellUpAmt == 0, "Non zero Up token amount");

            if (!desc.srcToken.isETH()) {
                desc.srcToken.safeTransferFrom(msg.sender, address(this), desc.amount);
                desc.srcToken.safeApprove(address(openOcean), desc.amount);
            }

            returnAmt = openOcean.swap{value: msg.value}(caller, desc, calls);
        } else {
            require(upAddr != address(0), "Zero address");

            if (buyUp == true && sellUp == false) {
                require(desc.dstReceiver == address(this), "Invalid dstReceiver address");
                require(sellUpAmt == 0, "Non zero Up token amount");
                
                if (!desc.srcToken.isETH()) {
                    desc.srcToken.safeTransferFrom(msg.sender, address(this), desc.amount);
                    desc.srcToken.safeApprove(address(openOcean), desc.amount);
                }

                uint256 swappedAmt = openOcean.swap{value: msg.value}(caller, desc, calls);
                require(swappedAmt > 0, "Zero amount");

                if (!isUpSwapPair(address(IUpSingleToken(upAddr).underlying()))) {
                    require(desc.dstToken == IUpSingleToken(upAddr).underlying(), "Invalid dstToken address");

                    desc.dstToken.safeApprove(upAddr, swappedAmt);
                    returnAmt = IUpSingleToken(upAddr).mintWithBacking(swappedAmt, msg.sender);
                } else if (isUpSwapPair(address(IUpLPToken(upAddr).underlying()))) {
                    returnAmt = _swapWithNonUnderlying1(desc, upAddr, swappedAmt);
                }
            } else if (buyUp == false && sellUp == true) {
                require(desc.dstReceiver != address(this), "Invalid dstReceiver address");
                require(sellUpAmt > 0, "Zero Up token amount");

                IERC20(upAddr).safeTransferFrom(msg.sender, address(this), sellUpAmt);

                if (!isUpSwapPair(address(IUpSingleToken(upAddr).underlying()))) {
                    require(desc.srcToken == IUpSingleToken(upAddr).underlying(), "Invalid srcToken address");
                    
                    uint256 swappedAmt = IUpSingleToken(upAddr).sell(sellUpAmt);
                    require(swappedAmt > 0, "Zero amount");

                    require(desc.amount <= swappedAmt, "Invalid Underlying token amount");
                    desc.srcToken.safeApprove(address(openOcean), desc.amount);
                    returnAmt = openOcean.swap{value: msg.value}(caller, desc, calls);
                } else if (isUpSwapPair(address(IUpLPToken(upAddr).underlying()))) {
                    returnAmt = _swapWithNonUnderlying2(caller, desc, calls, upAddr, sellUpAmt);
                }
            }
        }
    }

    /// @dev perform swapping via only Up token with Underlying token
    function swapWithUnderlying(address upAddr, bool sellUnderlying, bool sellUp, uint256 sellUnderlyingAmt, uint256 sellUpAmt, bool useToken0, bool useToken1) external nonZeroAddr(upAddr) whenNotPaused returns (uint256 returnAmt) {
        require(!(sellUnderlying == true && sellUp == true) && !(sellUnderlying == false && sellUp == false), "Invalid sellUnderlying and sellUp");
        
        if (sellUnderlying == true && sellUp == false) {
            require(sellUnderlyingAmt > 0 && sellUpAmt == 0, "Invalid sell token amount");

            if (!isUpSwapPair(address(IUpSingleToken(upAddr).underlying()))) {
                IUpSingleToken(upAddr).underlying().safeTransferFrom(msg.sender, address(this), sellUnderlyingAmt);
                IUpSingleToken(upAddr).underlying().safeApprove(upAddr, sellUnderlyingAmt);
                returnAmt = IUpSingleToken(upAddr).mintWithBacking(sellUnderlyingAmt, msg.sender);
            } else if (isUpSwapPair(address(IUpLPToken(upAddr).underlying()))) {
                address token0 = IUpLPToken(upAddr).underlying().token0();
                address token1 = IUpLPToken(upAddr).underlying().token1();
                
                if (useToken0 && !useToken1) {
                    returnAmt = _swapWithUnderlying1(upAddr, token0, token1, sellUnderlyingAmt);
                } else if (!useToken0 && useToken1) {
                    returnAmt = _swapWithUnderlying1(upAddr, token1, token0, sellUnderlyingAmt);
                }
            }
        } else if (sellUnderlying == false && sellUp == true) {
            require(sellUnderlyingAmt == 0 && sellUpAmt > 0, "Invalid sell token amount");
            IERC20(upAddr).safeTransferFrom(msg.sender, address(this), sellUpAmt);

            if (!isUpSwapPair(address(IUpSingleToken(upAddr).underlying()))) {
                returnAmt = IUpSingleToken(upAddr).sellTo(sellUpAmt, msg.sender);
            } else if (isUpSwapPair(address(IUpLPToken(upAddr).underlying()))) {
                uint256 swappedAmt = IUpLPToken(upAddr).sell(sellUpAmt);
                require(swappedAmt > 0, "Zero amount");
                
                address token0 = IUpLPToken(upAddr).underlying().token0();
                address token1 = IUpLPToken(upAddr).underlying().token1();

                IUpLPToken(upAddr).underlying().approve(address(router), swappedAmt);
                (uint256 amtA, uint256 amtB) = router.removeLiquidity(token0, token1, swappedAmt, 0, 0, address(this), block.timestamp);
                
                if (useToken0 && !useToken1) {
                    returnAmt = _swapWithUnderlying2(token0, token1, amtA, amtB);
                } else if (!useToken0 && useToken1) {
                    returnAmt = _swapWithUnderlying2(token1, token0, amtB, amtA);
                }
            }
        }
    }

    /// @notice compare two strings
    function compareStrings(string memory s1, string memory s2) public pure returns (bool) {
        if (bytes(s1).length != bytes(s2).length) {
            return false;
        } else {
            return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
        }
    }

    /// @notice whether target token symbol is pair token symbol or not
    function isLPSymbol(address target) public pure returns (bool) {
        string memory tokenSymbol;
        try IUpSwapPair(target).symbol() returns (string memory _tokenSymbol) {
            tokenSymbol = _tokenSymbol;
        } catch Error(string memory) {
            return false;
        } catch (bytes memory) {
            return false;
        }

        if (bytes(tokenSymbol).length == 0) {
           return false;
        }
        return compareStrings(tokenSymbol, "Cake-LP");
    }

    /// @notice whether target address is pair token address or not
    function isUpSwapPair(address target) public view returns (bool) {
        uint256 csize;
        assembly {
            csize := extcodesize(target)
        }
        if (csize == 0) {
            return false;
        } else if (target.code.length == 0) {
            return false;
        }

        address token0;
        address token1;
        if (isLPSymbol(target)) {
            try IUpSwapPair(target).token0() returns (address _token0) {
                token0 = _token0;
            } catch Error(string memory) {
                return false;
            } catch (bytes memory) {
                return false;
            }

            try IUpSwapPair(target).token1() returns (address _token1) {
                token1 = _token1;
            } catch Error(string memory) {
                return false;
            } catch (bytes memory) {
                return false;
            }
            return target == factory.getPair(token0, token1);
        } else {
            return false;
        }
    }

    /* ========== Internal Functions ========== */

    function _pairSwap(address _from, uint256 _amount, address _to, address _receiver) internal returns (uint256) {
        address[] memory path = new address[](2);

        path[0] = _from;
        path[1] = _to;

        uint256[] memory amounts = router.swapExactTokensForTokens(_amount, 0, path, _receiver, block.timestamp);
        return amounts[amounts.length - 1];
    }

    function _swapWithNonUnderlying1(IOpenOceanExchange.SwapDescription calldata desc, address _upAddr, uint256 _swappedAmt) internal returns (uint256 returnAmt) {
        require(address(desc.srcToken) != IUpLPToken(_upAddr).underlying().token0() && address(desc.srcToken) != IUpLPToken(_upAddr).underlying().token1(), "Invalid srcToken address");
        require(address(desc.dstToken) == IUpLPToken(_upAddr).underlying().token0() || address(desc.dstToken) == IUpLPToken(_upAddr).underlying().token1(), "Invalid dstToken address");

        address otherToken = address(desc.dstToken) == IUpLPToken(_upAddr).underlying().token0() ? IUpLPToken(_upAddr).underlying().token1() : IUpLPToken(_upAddr).underlying().token0();
        
        desc.srcToken.safeApprove(address(adapter), _swappedAmt);
        uint256 liquidityAmt = adapter.zapIn(address(desc.srcToken), _swappedAmt, otherToken);
        require(liquidityAmt > 0, "Zero amount");

        IUpLPToken(_upAddr).underlying().approve(_upAddr, liquidityAmt);
        returnAmt = IUpLPToken(_upAddr).mintWithBacking(liquidityAmt, msg.sender);
    }

    function _swapWithNonUnderlying2(IOpenOceanCaller caller, IOpenOceanExchange.SwapDescription calldata desc, IOpenOceanCaller.CallDescription[] calldata calls, address _upAddr, uint256 _sellUpAmt) internal returns (uint256 returnAmt) {
        require(address(desc.srcToken) == IUpLPToken(_upAddr).underlying().token0() || address(desc.srcToken) == IUpLPToken(_upAddr).underlying().token1(), "Invalid srcToken address");
        require(address(desc.dstToken) != IUpLPToken(_upAddr).underlying().token0() && address(desc.dstToken) != IUpLPToken(_upAddr).underlying().token1(), "Invalid dstToken address");

        uint256 swappedAmt = IUpLPToken(_upAddr).sell(_sellUpAmt);
        require(swappedAmt > 0, "Zero amount");

        IUpLPToken(_upAddr).underlying().approve(address(adapter), swappedAmt);
        uint256 totalAmt = adapter.zapOut(address(IUpLPToken(_upAddr).underlying()), swappedAmt, address(desc.srcToken));
        require(desc.amount <= totalAmt, "Invalid srcToken amount");

        desc.srcToken.safeApprove(address(openOcean), desc.amount);
        returnAmt = openOcean.swap{value: msg.value}(caller, desc, calls);
    }

    function _swapWithUnderlying1(address _upAddr, address _tokenA, address _tokenB, uint256 _amount) internal returns (uint256 returnAmt) {
        uint256 sellAmt = _amount.div(2);

        IERC20(_tokenA).safeApprove(address(router), sellAmt);
        uint256 otherAmt = _pairSwap(_tokenA, sellAmt, _tokenB, address(this));

        IERC20(_tokenA).safeApprove(address(router), _amount.sub(sellAmt));
        IERC20(_tokenB).safeApprove(address(router), otherAmt);

        (,,uint256 liquidityAmt) = router.addLiquidity(_tokenA, _tokenB, _amount.sub(sellAmt), otherAmt, 0, 0, address(this), block.timestamp);
        require(liquidityAmt > 0, "Zero amount");

        IUpLPToken(_upAddr).underlying().approve(_upAddr, liquidityAmt);
        returnAmt = IUpLPToken(_upAddr).mintWithBacking(liquidityAmt, msg.sender);
    }

    function _swapWithUnderlying2(address _tokenA, address _tokenB, uint256 _amountA, uint256 _amountB) internal returns (uint256 returnAmt) {
        IERC20(_tokenB).safeApprove(address(router), _amountB);
        uint256 otherAmt = _pairSwap(_tokenB, _amountB, _tokenA, address(this));
        IERC20(_tokenA).safeTransfer(msg.sender, _amountA.add(otherAmt));
        returnAmt = _amountA.add(otherAmt);
    }

    /* ========== Restricted Functions ========== */

    function updateOpenOcean(address _newOpenOceanAddr) external nonZeroAddr(_newOpenOceanAddr) onlyOwner {
        openOcean = IOpenOceanExchange(_newOpenOceanAddr);
    }

    function updateRouter(address _newRouterAddr) external nonZeroAddr(_newRouterAddr) onlyOwner {
        router = IUpSwapRouter02(_newRouterAddr);
    }

    function updateFactory(address _newFactoryAddr) external nonZeroAddr(_newFactoryAddr) onlyOwner {
        factory = IUpSwapFactory(_newFactoryAddr);
    }

    function updateAdapter(address _newAdapterAddr) external nonZeroAddr(_newAdapterAddr) onlyOwner {
        adapter = IAdapter(_newAdapterAddr);
    }

    function pause() external onlyOwner {
        super._pause();
    }

    function unpause() external onlyOwner {
        super._unpause();
    }

    /// @notice Retrieves funds accidently sent directly to the contract address
    function rescueFunds(IERC20 token, uint256 amount) external onlyOwner {
        token.universalTransfer(payable(msg.sender), amount);
    }

    /// @notice Destroys the contract and sends eth to sender. Use with caution.
    function destroy() external onlyOwner {
        selfdestruct(payable(msg.sender));
    }
    
    /// @dev decoder encoded abi
    function abiDecoder(bytes calldata _data) external pure returns (IOpenOceanCaller caller, IOpenOceanExchange.SwapDescription memory desc, IOpenOceanCaller.CallDescription[] memory calls) {
        (caller, desc, calls) = abi.decode(_data, (IOpenOceanCaller, IOpenOceanExchange.SwapDescription, IOpenOceanCaller.CallDescription[]));
    }
}