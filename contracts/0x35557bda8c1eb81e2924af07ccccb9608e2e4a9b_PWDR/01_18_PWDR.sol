// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import { IUniswapV2Factory } from '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import { IUniswapV2Router02 } from '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import { IPWDR } from "../interfaces/IPWDR.sol";
import { IAvalanche } from '../interfaces/IAvalanche.sol';
import { PWDRBase } from "./PWDRBase.sol";

contract PWDR is IPWDR, PWDRBase {
    event EpochUpdated(address _address, uint256 _epoch, uint256 _phase);

    uint256 public override constant MAX_SUPPLY = 21000000 * 1e18; // max supply 21M

    bool public override maxSupplyHit; // has max supply been reached
    uint256 public override transferFee; // PWDR transfer fee, 1 = 0.1%. Default 1.5%

    uint256 public override currentEpoch;
    uint256 public override currentPhase; // current phase; 0 = Accumulation ,1 = Distribution
    uint256[] public override epochMaxSupply; // max total supply for each epoch, running total
    uint256[] public override epochBaseRate; // base APR of Slope rewards
    
    // Mapping of whitelisted sender and recipient addresses that don't pay the transfer fee. 
    // Allows PWDR token holders to whitelist future contracts
    mapping(address => bool) public senderWhitelist;
    mapping(address => bool) public recipientWhitelist;

    modifier Accumulation {
        require(
            currentPhase == 0,
            "PWDR is not in Accumulation"
        );
        _;
    }
    
    modifier MaxSupplyNotReached {
        require(!maxSupplyHit, "Max PWDR Supply has been reached");
        _;
    }

    modifier OnlyAuthorized {
        require(
            msg.sender == avalancheAddress()
            || msg.sender == lgeAddress()
            || msg.sender == slopesAddress(),
            "Only LGE, Slopes, and Avalanche contracts can call this function"
        );
        _;
    }

    constructor(address addressRegistry) 
        public 
        PWDRBase(addressRegistry, "Altitude", "PWDR") 
    {
        transferFee = 15;
        _initializeEpochs();
    }

    function _initializeEpochs() 
        private 
    {
        _setupEpoch(5250000 * 1e18, 0); // 5.25M PWDR for LGE
        _setupEpoch(13250000 * 1e18, 800); // +8M PWDR, 800%
        _setupEpoch(17250000 * 1e18, 400); // +4M PWDR, 400%
        _setupEpoch(19250000 * 1e18, 200); // +2M PWDR, 200%
        _setupEpoch(20250000 * 1e18, 100); // +1M PWDR, 100%
        _setupEpoch(20750000 * 1e18, 50); // +500K PWDR, 50%
        _setupEpoch(21000000 * 1e18, 25); // +250K PWDR, 25%
    }

    function _setupEpoch(uint256 maxSupply, uint256 baseRate) 
        private 
    {
        epochMaxSupply.push(maxSupply);
        epochBaseRate.push(baseRate);
    }

    function currentMaxSupply() 
        external 
        view
        override 
        returns (uint256)
    {
        return epochMaxSupply[currentEpoch];
    }

    function currentBaseRate() 
        external 
        view 
        override
        returns (uint256)
    {
        return epochBaseRate[currentEpoch];
    }

    function accumulating()
        external
        view
        override
        returns (bool)
    {
        return currentEpoch > 0 && currentEpoch <= 6
            && currentPhase == 0;
    }

    function updateEpoch(uint256 _epoch, uint256 _phase)
        external
        override
        OnlyAuthorized
    {
        // require valid update calls
        if (currentPhase == 0) {
            require(
                _epoch == currentEpoch && _phase == 1,
                "Invalid Epoch Phase Update Call"
            );
        } else {
            // change this to _epoch == currentEpoch + 1 in prod
            require(
                _epoch > currentEpoch && _phase == 0,
                "Invalid Epoch Update Call"
            );
        }

        currentEpoch = _epoch;
        currentPhase = _phase;

        emit EpochUpdated(_msgSender(), _epoch, _phase);
    }

    // Creates `_amount` PWDR token to `_to`. 
    // Can only be called by the LGE, Slopes, and Avalanche contracts
    //  when epoch and max supply numbers allow
    function mint(address _to, uint256 _amount)
        external
        override
        Accumulation
        MaxSupplyNotReached
        OnlyAuthorized
    {
        uint256 supply = totalSupply();
        uint256 epochSupply = epochMaxSupply[currentEpoch];

        // update phase if epoch max supply is hit during this mint
        if (supply.add(_amount) >= epochSupply) {
            _amount = epochSupply.sub(supply);
            
            if (supply.add(_amount) >= MAX_SUPPLY) {
                maxSupplyHit = true;
            }

            // activate gets called at every accumulation end to reset rewards
            IAvalanche(avalancheAddress()).activate();            

            if (currentEpoch == 0) {
                currentEpoch += 1;
            } else {
                currentPhase += 1;
            }
            emit EpochUpdated(_msgSender(), currentEpoch, currentPhase);
        }

        if (_amount > 0) {
            _mint(_to, _amount);
        }
    }

    // Transfer override to support transfer fees that are sent to Avalanche
    function _transfer(
        address sender, 
        address recipient, 
        uint256 amount
    ) 
        internal
        override
    {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 transferFeeAmount;
        uint256 tokensToTransfer;
        if (amount > 0) {
            address avalancheAddress = avalancheAddress();

            // Send a fee to the Avalanche staking contract if this isn't a whitelisted transfer
            if (_isWhitelistedTransfer(sender, recipient) != true) {
                transferFeeAmount = amount.mul(transferFee).div(1000);
                _balances[avalancheAddress] = _balances[avalancheAddress].add(transferFeeAmount);
                IAvalanche(avalancheAddress).addPwdrReward(sender, transferFeeAmount);
                emit Transfer(sender, avalancheAddress, transferFeeAmount);
            }
            tokensToTransfer = amount.sub(transferFeeAmount);
            _balances[sender] = _balances[sender].sub(tokensToTransfer, "ERC20: transfer amount exceeds balance");

            if (tokensToTransfer > 0) {
                _balances[recipient] = _balances[recipient].add(tokensToTransfer);

                // If the Avalanche is the transfer recipient, add rewards to keep balances updated
                if (recipient == avalancheAddress) {
                    IAvalanche(avalancheAddress).addPwdrReward(sender, tokensToTransfer);
                }
            }

        }
        emit Transfer(sender, recipient, tokensToTransfer);
    }

    // Admin calls this at token deployment to setup PWDR-LP LGE transfers
    function calculateUniswapPoolAddress() 
        external
        view 
        HasPatrol("ADMIN")
        returns (address)
    {
        address uniswapRouter = uniswapRouterAddress();
        address wethAddress = wethAddress();

        // Calculate the address the PWDR-ETH Uniswap pool will exist at
        address factoryAddress = IUniswapV2Router02(uniswapRouter).factory();
        // return IUniswapV2Factory(factoryAddress).createPair(wethAddress, address(this));

        // token0 must be strictly less than token1 by sort order to determine the correct address
        (address token0, address token1) = address(this) < wethAddress 
            ? (address(this), wethAddress) 
            : (wethAddress, address(this));

        //uniswap address pre-calculation using create2
        return address(uint(keccak256(abi.encodePacked(
            hex'ff',
            factoryAddress,
            keccak256(abi.encodePacked(token0, token1)),
            hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f'
        ))));
    }

    // Sets the PWDR transfer fee that gets rewarded to Avalanche stakers. Can't be higher than 5%.
    function setTransferFee(uint256 _transferFee) 
        public
        override
        HasPatrol("ADMIN")
    {
        require(_transferFee <= 50, "over 5%");
        transferFee = _transferFee;
    }

    // Add an address to the sender or recipient transfer whitelist
    function addToTransferWhitelist(bool _addToSenderWhitelist, address _address) 
        public
        override 
        HasPatrol("ADMIN") 
    {
        if (_addToSenderWhitelist == true) {
            senderWhitelist[_address] = true;
        } else {
            recipientWhitelist[_address] = true;
        }
    }

    // Remove an address from the sender or recipient transfer whitelist
    function removeFromTransferWhitelist(bool _removeFromSenderWhitelist, address _address) 
        public
        override
        HasPatrol("ADMIN") 
    {
        if (_removeFromSenderWhitelist == true) {
            senderWhitelist[_address] = false;
        } else  {
            recipientWhitelist[_address] = false;
        }
    }

    // Internal function to determine if a PWDR transfer is being sent or received by a whitelisted address
    function _isWhitelistedTransfer(
        address _sender, 
        address _recipient
    ) 
        internal 
        view 
        returns (bool) 
    {
        // Ecosytem contracts should not pay transfer fees
        return _sender == avalancheAddress() || _recipient == avalancheAddress()
            || _sender == lgeAddress() || _recipient == lgeAddress()
            || _sender == slopesAddress() || _recipient == slopesAddress()
            || senderWhitelist[_sender] == true || recipientWhitelist[_recipient] == true;
    }
}