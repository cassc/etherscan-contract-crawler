// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IBTCInscriber.sol";
import "./interfaces/ILiquidDelegate.sol";
import "./interfaces/IWrappedPunk.sol";
import "./interfaces/INFTFlashBorrower.sol";
import "./interfaces/ICryptoPunks.sol";

contract LiquidPunkInscribe is INFTFlashBorrower {
    ILiquidDelegate LIQUID_DELEGATE = ILiquidDelegate(0x2E7AfEE4d068Cdcc427Dba6AE2A7de94D15cf356);
    IBTCInscriber BTC_INSCRIBER = IBTCInscriber(0x47C3DC5623387248df3C350db91490c9bEDAD5cd);
    IWrappedPunk WRAPPED_PUNK = IWrappedPunk(0xb7F7F6C52F2e2fdb1963Eab30438024864c313F6);
    ICryptoPunks CRYPTO_PUNK = ICryptoPunks(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB);
    
    bytes32 public constant CALLBACK_SUCCESS = keccak256("INFTFlashBorrower.onFlashLoan");
    mapping(address => uint256) public userDeposits;

    error NotAWrappedPunk();
    error InsufficientDeposits();
    error WithdrawFailed();

    function deposit() external payable {
        userDeposits[msg.sender] += msg.value;
    }

    function withdraw() external {
        uint256 balance = userDeposits[msg.sender];
        userDeposits[msg.sender] = 0;
        if(balance > 0) {
            (bool sent, ) = payable(msg.sender).call{value: (balance)}("");
            if(!sent) { revert WithdrawFailed(); }
        }

    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 id,
        bytes calldata data
    ) external returns (bytes32) {
        if(token != address(WRAPPED_PUNK)) { revert NotAWrappedPunk(); }

        uint256 totalCost = BTC_INSCRIBER.inscriptionBaseFee() - BTC_INSCRIBER.inscriptionDiscount(address(CRYPTO_PUNK));
        if(userDeposits[initiator] < totalCost) { revert InsufficientDeposits(); }
        userDeposits[initiator] -= totalCost;

        address wpProxy = WRAPPED_PUNK.proxyInfo(address(this));
        if(wpProxy == address(0)) {
            WRAPPED_PUNK.registerProxy();
            wpProxy = WRAPPED_PUNK.proxyInfo(address(this));
        }

        WRAPPED_PUNK.burn(id);
        BTC_INSCRIBER.inscribeNFT{value: totalCost}(address(CRYPTO_PUNK), id, string(data));
        CRYPTO_PUNK.transferPunk(wpProxy, id);
        WRAPPED_PUNK.mint(id);

        WRAPPED_PUNK.setApprovalForAll(address(LIQUID_DELEGATE), true);

        return CALLBACK_SUCCESS;
    }
}