// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./BasicCoin.sol";

/// @custom:security-contact [email protected]

interface IUSDT {
    function transferFrom(address, address, uint256) external;
}

contract Sweet is BasicCoin {
    mapping(address => recdBasicUnit) internal m_recdUSDT;

    constructor(
        string memory name,
        string memory symbol
    ) payable BasicCoin(name, symbol) {
        // We initialize 10 billion tokens total in this contact
        _mint(address(this), 1_000_000_000 * 10 ** uint256(decimals()));
    }

    // 2. external functions
    function claimSweet(
        uint256 nonce,
        uint256 amount,
        uint256 tag,
        bytes memory signature
    ) external {
        require(
            _verifyBasicSingleData(
                msg.sender,
                nonce,
                amount,
                tag,
                this.claimSweet.selector,
                signature
            ),
            "invalid signer, on claiming Sweet"
        );
        _claimCoin(nonce, amount, tag);
    }

    function spendSweet(
        uint256 nonce,
        uint256 amount,
        uint256 tag,
        bytes memory signature
    ) external {
        require(
            _verifyBasicSingleData(
                msg.sender,
                nonce,
                amount,
                tag,
                this.spendSweet.selector,
                signature
            ),
            "invalid signer, on spending Sweet"
        );
        _spendCoin(nonce, amount, tag);
    }

    function _verifyUSDTSpendData(
        address addrToken,
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
                    addrToken,
                    addrUser,
                    selector,
                    block.chainid
                )
            )
        );
        address signer = ECDSA.recover(orderHash, signature);
        return (signer == m_OpSigner);
    }

    event evUSDTSpend(address user, uint256 nonce, uint256 amount, uint256 tag);

    function spendUSDT(
        address token,
        uint256 nonce,
        uint256 amount,
        uint256 tag,
        bytes memory signature
    ) external {
        require(
            m_recdUSDT[msg.sender].nonce == nonce - 1,
            "wrong nonce, on spending USDT"
        );
        require(
            _verifyUSDTSpendData(
                token,
                msg.sender,
                nonce,
                amount,
                tag,
                this.spendUSDT.selector,
                signature
            ),
            "invalid signer, on spending USDT"
        );

        IUSDT(token).transferFrom(msg.sender, m_Treasury, amount);

        // update records
        m_recdUSDT[msg.sender].nonce = nonce;
        m_recdUSDT[msg.sender].amount.push(amount);
        m_recdUSDT[msg.sender].tag.push(tag);

        emit evUSDTSpend(msg.sender, nonce, amount, tag);
    }

    function viewSweetInfo() external view returns (address, address, uint256) {
        uint256 remain = balanceOf(address(this));
        return (m_OpSigner, m_Treasury, remain);
    }

    function viewUSDTHist(
        address addr
    ) external view returns (recdBasicUnit memory) {
        return m_recdUSDT[addr];
    }
}