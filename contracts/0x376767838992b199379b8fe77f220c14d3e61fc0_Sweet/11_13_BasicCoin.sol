// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./IBasicCoin.sol";
import "./IBasicStake.sol";

// import "./IBaseStake.sol";

/// @custom:security-contact [email protected]

contract BasicCoin is ERC20, ERC20Burnable, Ownable, IBasicCoin {
    // 1.[Types]: state variable
    mapping(address => recdBasicUnit) internal m_recdClaim;
    mapping(address => recdBasicUnit) internal m_recdSpend;

    address internal m_OpSigner;
    address internal m_Treasury;

    uint256 private immutable ST_OPSIGNER = 0x20;
    uint256 private immutable ST_TREASURY = 0x40;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        m_OpSigner = msg.sender;
        m_Treasury = msg.sender;
    }

    // 2.[Funtions]: coin operation
    function _claimCoin(uint256 nonce, uint256 amount, uint256 tag) internal {
        // check the nonce
        require(
            m_recdClaim[msg.sender].nonce == nonce - 1,
            "wrong nonce, on claiming"
        );

        ERC20(this).transfer(msg.sender, amount);

        // update records
        m_recdClaim[msg.sender].nonce = nonce;
        m_recdClaim[msg.sender].amount.push(amount);
        m_recdClaim[msg.sender].tag.push(tag);

        // event
        emit evClaim(msg.sender, nonce, amount, tag);
    }

    function _spendCoin(uint256 nonce, uint256 amount, uint256 tag) internal {
        // check the nonce
        require(
            m_recdSpend[msg.sender].nonce == nonce - 1,
            "wrong nonce, on spending"
        );

        transfer(m_Treasury, amount);

        // update records
        m_recdSpend[msg.sender].nonce = nonce;
        m_recdSpend[msg.sender].amount.push(amount);
        m_recdSpend[msg.sender].tag.push(tag);

        // event
        emit evSpend(msg.sender, nonce, amount, tag);
    }

    function _stakeCoin(
        IBasicStake conStake,
        address addrStaker,
        uint256 nonce,
        uint256[] memory aryTime,
        uint256[] memory aryAmount
    ) internal {
        require(conStake != IBasicStake(address(0)), "stake contract not set");

        uint256 deltaT = 300; // 5 minutes, for time-adjusting
        uint256 sum = 0;

        for (uint256 i = 0; i < aryTime.length; i++) {
            // block timestamp must smaller than the locked time
            assert(block.timestamp < (aryTime[i] + deltaT));
        }
        for (uint256 i = 0; i < aryAmount.length; i++) {
            sum += aryAmount[i];
        }

        ERC20(this).transfer(address(conStake), sum);
        conStake.applyStake(addrStaker, nonce, aryTime, aryAmount);
    }

    // 3.[Functions]: verification
    function _verifyBasicSingleData(
        address addrUser,
        uint256 nonce,
        uint256 amount,
        uint256 tag,
        bytes4 selector,
        bytes memory signature
    ) internal view returns (bool) {
        bytes32 orderHash = ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    tag,
                    amount,
                    nonce,
                    addrUser,
                    selector,
                    block.chainid
                )
            )
        );
        address signer = ECDSA.recover(orderHash, signature);
        return (signer == m_OpSigner);
    }

    // 2.2 Verify signature for staking:
    function _verifyBasicArrayData(
        address addrUser,
        uint256 nonce,
        uint256[] memory aryTime,
        uint256[] memory aryAmount,
        bytes4 selector,
        bytes memory signature
    ) internal view returns (bool) {
        require(
            aryTime.length == aryAmount.length,
            "timestamp and amount array length should be equal"
        );
        require(aryTime.length <= 10, "no more 10 arrays");

        // check signature
        bytes32 orderHash = ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    addrUser,
                    nonce,
                    aryTime,
                    aryAmount,
                    selector,
                    block.chainid
                )
            )
        );
        address signer = ECDSA.recover(orderHash, signature);
        return (signer == m_OpSigner);
    }

    // 4.[Functions]: setting
    function setOpSigner(address addr) external onlyOwner {
        require(
            addr != address(0) && addr != m_OpSigner,
            "invalid address, on signer setting"
        );

        address addrOld = m_OpSigner;
        m_OpSigner = addr;

        emit evSetup(addrOld, m_OpSigner, ST_OPSIGNER);
    }

    function setTreasury(address addr) external onlyOwner {
        require(
            addr != address(0) && addr != m_Treasury,
            "invalid address, on treasury setting"
        );

        address addrOld = m_Treasury;
        m_Treasury = addr;

        emit evSetup(addrOld, m_Treasury, ST_TREASURY);
    }

    // 5.[Functions]: view
    function viewClaimHist(
        address addr
    ) external view returns (recdBasicUnit memory) {
        return m_recdClaim[addr];
    }

    function viewSpendHist(
        address addr
    ) external view returns (recdBasicUnit memory) {
        return m_recdSpend[addr];
    }
}