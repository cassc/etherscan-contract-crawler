//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./IBEP20.sol";
import "./Address.sol";
import "./NarfexFiat.sol";
import "./Ownable.sol";

/// @title Narfex Exchanger Router
/// @author Danil Sakhinov
/// @notice Router for manipulating with fiat tokens for internal use in the Narfex exchange
contract NarfexExchangerRouter is Ownable {
    using Address for address;

    INarfexFiatFactory private _factory;
    address private _nrfx; // Narfex Token
    address public _exchangerWallet; // Wallet for currencies supported on Binance
    address public _exchangerWalletSecondary; // Wallet for currencies not supported on Binance

    constructor(
        address factoryAddress,
        address nrfxAddress,
        address exchangerAddress
        ) {
        _factory = INarfexFiatFactory(factoryAddress);
        _nrfx = nrfxAddress;
        _exchangerWallet = exchangerAddress;
        // Set the owner address as the secondary exchanger wallet
        _exchangerWalletSecondary = INarfexFiatFactory(factoryAddress).owner();
    }

    /**
     * @dev Returns the bep token owner.
     */
    function owner() override public view returns (address) {
        return _factory.owner();
    }

    /// @notice Change Exchanger wallet address
    /// @param _address New wallet address
    function changeExchangerWalletAddress(address _address) public onlyOwner {
        _exchangerWallet = _address;
    }
    
    /// @notice Change the secondary Exchanger wallet address
    /// @param _address New wallet address
    function changeExchangerWalletSecondaryAddress(address _address) public onlyOwner {
        _exchangerWalletSecondary = _address;
    }

    /// @notice Exchange fiat to fiat on the selected address
    /// @param _fromAddress Wallet address
    /// @param _fromFiat Fiat to be burned
    /// @param _toFiat Fiat to be minted
    /// @param _fromAmount Amount of fiat to be burned
    /// @param _toAmount Amount of fiat to be minted
    function exchangeFiatToFiat(
        address _fromAddress,
        address _fromFiat,
        address _toFiat,
        uint256 _fromAmount,
        uint256 _toAmount
        ) public onlyOwner {
            NarfexFiat(_fromFiat).burnFrom(_fromAddress, _fromAmount);
            NarfexFiat(_toFiat).mintTo(_fromAddress, _toAmount);
        }

    /// @notice Exchange token to fiat on the selected address
    /// @param _fromAddress Wallet address
    /// @param _fromToken Fiat to be burned
    /// @param _toFiat Fiat to be minted
    /// @param _fromAmount Amount of fiat to be burned
    /// @param _toAmount Amount of fiat to be minted
    function exchangeCryptoToFiat(
        address _fromAddress,
        address _fromToken,
        address _toFiat,
        uint256 _fromAmount,
        uint256 _toAmount
    ) public onlyOwner {
        if (_fromToken == _nrfx) {
            IBEP20(_fromToken).transferFrom(_fromAddress, _exchangerWalletSecondary, _fromAmount);
        } else {
            IBEP20(_fromToken).transferFrom(_fromAddress, _exchangerWallet, _fromAmount);
        }
        NarfexFiat(_toFiat).mintTo(_fromAddress, _toAmount);
    }

    /// @notice Exchahge fiat to fiat with referral deductions to the agent
    /// @param _fromAddress Wallet address
    /// @param _fromToken Fiat to be burned
    /// @param _toFiat Fiat to be minted
    /// @param _fromAmount Amount of fiat to be burned
    /// @param _toAmount Amount of fiat to be minted
    /// @param _agent Agent wallet address
    /// @param _bounty Referral reward
    function exchangeFiatToFiatWithBounty(
        address _fromAddress,
        address _fromToken,
        address _toFiat,
        uint256 _fromAmount,
        uint256 _toAmount,
        address _agent,
        uint256 _bounty
    ) public onlyOwner {
        exchangeFiatToFiat(_fromAddress, _fromToken, _toFiat, _fromAmount, _toAmount);
        NarfexFiat(_fromToken).mintTo(_agent, _bounty);
    }

    /// @notice Exchange token to fiat with referral deductions to the agent
    /// @param _fromAddress Wallet address
    /// @param _fromToken Fiat to be burned
    /// @param _toFiat Fiat to be minted
    /// @param _fromAmount Amount of fiat to be burned
    /// @param _toAmount Amount of fiat to be minted
    /// @param _agent Agent wallet address
    /// @param _bounty Referral reward
    function exchangeCryptoToFiatWithBounty(
        address _fromAddress,
        address _fromToken,
        address _toFiat,
        uint256 _fromAmount,
        uint256 _toAmount,
        address _agent,
        uint256 _bounty
    ) public onlyOwner {
        exchangeCryptoToFiat(_fromAddress, _fromToken, _toFiat, _fromAmount, _toAmount);
        NarfexFiat(_toFiat).mintTo(_agent, _bounty);
    }

    /// @notice Burn fiat from the address with referral deductions to the agent
    /// @param _fromAddress Wallet address
    /// @param _fiat Fiat to be burned
    /// @param _amount Amount of fiat to be burned
    /// @param _agent Agent wallet address
    /// @param _bounty Referral reward
    function burnWithBounty(
        address _fromAddress,
        address _fiat,
        uint256 _amount,
        address _agent,
        uint256 _bounty
    ) public onlyOwner {
        NarfexFiat(_fiat).burnFrom(_fromAddress, _amount);
        NarfexFiat(_fiat).mintTo(_agent, _bounty);
    }
}