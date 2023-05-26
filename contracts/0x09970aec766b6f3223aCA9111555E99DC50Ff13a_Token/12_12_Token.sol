pragma solidity ^0.5.0;

import "Ownable.sol";
import "ERC20Detailed.sol";
import "ERC20Pausable.sol";
import "ERC20Burnable.sol";
import "ERC20.sol";
import "ECDSA.sol";
import "SafeMath.sol";

contract Token is ERC20, ERC20Detailed, ERC20Pausable, ERC20Burnable, Ownable {
    using ECDSA for bytes32;
    using SafeMath for uint256;

    event HashRedeemed(bytes32 indexed txHash, address indexed from);

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 initialSupply
    )
        ERC20Pausable()
        ERC20Burnable()
        ERC20Detailed(name, symbol, decimals)
        ERC20()
        public
    {
        require(initialSupply > 0);
        _mint(msg.sender, initialSupply);
    }

    /**
     * Returns the circulating supply (total supply minus tokens held by owner)
     */
    function circulatingSupply() public view returns (uint256) {
        return totalSupply().sub(balanceOf(owner()));
    }

    /**
     * Owner can withdraw any ERC20 token received by the contract
     */
    function transferAnyERC20Token(address tokenAddress, uint256 tokens) public onlyOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(owner(), tokens);
    }

    mapping(bytes32 => bool) invalidHashes;

    /**
     * Transfer tokens as the owner on his behalf for signer of signature.
     *
     * @param to address The address which you want to transfer to.
     * @param value uint256 The amount of tokens to be transferred.
     * @param gasPrice uint256 The price in tokens that will be paid per unit of gas.
     * @param nonce uint256 The unique transaction number per user.
     * @param signature bytes The signature of the signer.
     */
    function transferPreSigned(
        address to,
        uint256 value,
        uint256 gasPrice,
        uint256 nonce,
        bytes memory signature
    )
        public
        whenNotPaused
        returns (bool)
    {
        uint256 gas = gasleft();

        require(to != address(0));

        bytes32 payloadHash = transferPreSignedPayloadHash(address(this), to, value, gasPrice, nonce);

        // Recover signer address from signature
        address from = payloadHash.toEthSignedMessageHash().recover(signature);
        require(from != address(0), "Invalid signature provided.");

        // Generate transaction hash
        bytes32 txHash = keccak256(abi.encodePacked(from, payloadHash));

        // Make sure this transfer didn't happen yet
        require(!invalidHashes[txHash], "Transaction has already been executed.");

        // Mark hash as used
        invalidHashes[txHash] = true;

        // Initiate token transfer
        _transfer(from, to, value);

        // If a gas price is set, pay the sender of this transaction in tokens
        uint256 fee = 0;
        if (gasPrice > 0) {
            // 21000 base + ~14000 transfer + ~10000 event
            gas = 21000 + 14000 + 10000 + gas.sub(gasleft());
            fee = gasPrice.mul(gas);
            _transfer(from, tx.origin, fee);
        }

        emit HashRedeemed(txHash, from);

        return true;
    }

    /**
     * Calculates the hash for the payload used by transferPreSigned
     *
     * @param token address The address of this token.
     * @param to address The address which you want to transfer to.
     * @param value uint256 The amount of tokens to be transferred.
     * @param gasPrice uint256 The price in tokens that will be paid per unit of gas.
     * @param nonce uint256 The unique transaction number per user.
     */
    function transferPreSignedPayloadHash(
        address token,
        address to,
        uint256 value,
        uint256 gasPrice,
        uint256 nonce
    )
        public
        pure
        returns (bytes32)
    {
        /* "452d3c59": transferPreSignedPayloadHash(address,address,uint256,uint256,uint256) */
        return keccak256(abi.encodePacked(bytes4(0x452d3c59), token, to, value, gasPrice, nonce));
    }
}
