// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import {IBeanstalk, To, From} from "./interfaces/IBeanstalk.sol";
import {DepotFacet} from "./facets/DepotFacet.sol";
import {TokenSupportFacet} from "./facets/TokenSupportFacet.sol";
import {LibFunction} from "./libraries/LibFunction.sol";
import {LibFlashLoan} from "./libraries/LibFlashLoan.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/drafts/IERC20Permit.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC4494} from "./interfaces/IERC4494.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IFlashLoanReceiver} from "./interfaces/IFlashLoanReceiver.sol";
import {IPoolAddressesProvider} from "./interfaces/helpers/IPoolAddressesProvider.sol";
import {IPool} from "./interfaces/helpers/IPool.sol";



/**
 * @title FlashDepot
 * @author Publius, Brean
 * @notice Depot wraps Pipeline's Pipe functions to facilitate the loading of non-Ether assets in Pipeline
 * in the same transaction that loads Ether, Pipes calls to other protocols and unloads Pipeline.
 * @notice flashDepot is a fork of Depot that allows users to ultilize flash loans.
 * uses AaveV2 flash loans
 * https://evmpipeline.org
**/

contract FlashDepotAave is IFlashLoanReceiver, DepotFacet, TokenSupportFacet {

    using SafeERC20 for IERC20;
    
    IBeanstalk private constant beanstalk =
        IBeanstalk(0xC1E088fC1323b20BCBee9bd1B9fC9546db5624C5);
    IPool public constant override POOL = 
        IPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);

    IPoolAddressesProvider public constant override ADDRESSES_PROVIDER = 
        IPoolAddressesProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
    

    /**
     * 
     * FlashPipe
     * 
    **/

    // flash pipe embeds a flash loan call to balancer.
    // flash pipe calls {farm}, and converts data into bytes
    // to be compatable with pipeline. 
    function flashPipe(
        address[] memory assets,
        uint256[] memory amounts,
        bytes memory data
    ) external {    
        POOL.flashLoan(
            address(this), 
            assets, 
            amounts, 
            new uint256[](2),
            address(this),
            data,
            0
        );
    }

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address,
        bytes calldata userData
    ) external override returns (bool){
        for(uint i; i < assets.length; i++){
            IERC20(assets[i]).transfer(PIPELINE,amounts[i]);
        }

        if(userData.length != 0) {
            this.farm(abi.decode(userData, (bytes[])));
        }

        for (uint i = 0; i < assets.length; i++) {
            uint amountOwing = amounts[i] + premiums[i];
            IERC20(assets[i]).approve(address(POOL), amountOwing);
        }
        return true;
    }

    /**
     * 
     * Farm
     * 
    **/

    /**
     * @notice Execute multiple function calls in Depot.
     * @param data list of encoded function calls to be executed
     * @return results list of return data from each function call
     * @dev Implementation from https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/Multicall.sol.
    **/
    function farm(bytes[] calldata data)
        external
        payable
        returns (bytes[] memory results)
    {
        return _farm(data);
    }
    
    function _farm(bytes[] calldata data)
        internal
        returns (bytes[] memory results)
    {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);
            LibFunction.checkReturn(success, result);
            results[i] = result;
        }
    }

    /**
     *
     * Transfer
     *
    **/

    /**
     * @notice Execute a Beanstalk ERC-20 token transfer.
     * @dev See {TokenFacet-transferToken}.
     * @dev Only supports INTERNAL and EXTERNAL From modes.
    **/
    function transferToken(
        IERC20 token,
        address recipient,
        uint256 amount,
        From fromMode,
        To toMode
    ) external payable {
        if (fromMode == From.EXTERNAL) {
            token.transferFrom(msg.sender, recipient, amount);
        } else if (fromMode == From.INTERNAL) {
            beanstalk.transferInternalTokenFrom(
                token, 
                msg.sender, 
                recipient, 
                amount, 
                toMode
            );
        } else {
            revert("Mode not supported");
        }
    }

    /**
     * @notice Execute a single Beanstalk Deposit transfer.
     * @dev See {SiloFacet-transferDeposit}.
    **/
    function transferDeposit(
        address sender,
        address recipient,
        address token,
        uint32 season,
        uint256 amount
    ) external payable returns (uint256 bdv) {
        require(sender == msg.sender, "invalid sender");
        bdv = beanstalk.transferDeposit(
            msg.sender, 
            recipient, 
            token, 
            season, 
            amount
        );
    }

    /**
     * @notice Execute multiple Beanstalk Deposit transfers of a single Whitelisted Tokens.
     * @dev See {SiloFacet-transferDeposits}.
    **/
    function transferDeposits(
        address sender,
        address recipient,
        address token,
        uint32[] calldata seasons,
        uint256[] calldata amounts
    ) external payable returns (uint256[] memory bdvs) {
        require(sender == msg.sender, "invalid sender");
        bdvs = beanstalk.transferDeposits(
            msg.sender, 
            recipient, 
            token, 
            seasons, 
            amounts
        );
    }

    /**
     *
     * Permits
     *
    **/

    /**
     * @notice Execute a permit for an ERC-20 Token stored in a Beanstalk Farm balance.
     * @dev See {TokenFacet-permitToken}.
    **/
    function permitToken(
        address owner,
        address spender,
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        beanstalk.permitToken(
            owner, 
            spender, 
            token, 
            value, 
            deadline, 
            v, 
            r, 
            s
        );
    }

    /**
     * @notice Execute a permit for Beanstalk Deposits of a single Whitelisted Token.
     * @dev See {SiloFacet-permitDeposit}.
    **/
    function permitDeposit(
        address owner,
        address spender,
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        beanstalk.permitDeposit(
            owner, 
            spender, 
            token, 
            value, 
            deadline, 
            v, 
            r, 
            s
        );
    }

    /**
     * @notice Execute a permit for a Beanstalk Deposits of a multiple Whitelisted Tokens.
     * @dev See {SiloFacet-permitDeposits}.
    **/
    function permitDeposits(
        address owner,
        address spender,
        address[] calldata tokens,
        uint256[] calldata values,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        beanstalk.permitDeposits(
            owner, 
            spender, 
            tokens, 
            values, 
            deadline, 
            v, 
            r, 
            s
        );
    }

    function clipboardHelper(
        bool useEther,
        uint256 amount,
        LibFlashLoan.Type _type,
        uint256 returnDataIndex,
        uint256 copyIndex,
        uint256 pasteIndex
    ) external pure returns (bytes memory) {
        return LibFlashLoan.clipboardHelper(
            useEther,
            amount,
            _type,
            returnDataIndex,
            copyIndex,
            pasteIndex
        );
    }

    function advancedClipboardHelper(
        bool useEther,
        uint256 amount,
        LibFlashLoan.Type _type,
        uint256[] calldata returnDataIndex,
        uint256[] calldata copyIndex,
        uint256[] calldata pasteIndex
    ) external pure returns (bytes memory stuff) {
        return LibFlashLoan.advancedClipboardHelper(
            useEther,
            amount,
            _type,
            returnDataIndex,
            copyIndex,
            pasteIndex
        );
    }
}