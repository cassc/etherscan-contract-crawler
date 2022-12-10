// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/MinimalForwarder.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Simple minimal forwarder to be used together with an ERC2771 compatible contract. See {ERC2771Context}.
 *
 * MinimalForwarder is mainly meant for testing, as it is missing features to be a good production-ready forwarder. This
 * contract does not intend to have all the properties that are needed for a sound forwarding system. A fully
 * functioning forwarding system with good properties requires more complexity. We suggest you look at other projects
 * such as the GSN which do have the goal of building a system like that.
 */
contract MinimalForwarder is EIP712, Ownable {
    using ECDSA for bytes32;

    struct ForwardRequest {
        address from; /**Game admin/minter: _msgSender() at destination contract */
        address to; /**Destination contract */
        address relayer; /**Account that pays gas: _msgSender() at this contract */
        uint256 feeAmount; /**ERC20 amount to be paid to mint the NFT*/
        uint256 value; /**Ethers sent */
        uint256 gas; /**OZ default parameter gas */
        uint256 nonce; /**To invalidate previously signed transactions */
        bytes data; /**Encoded function name and parameters */
    }

    bytes32 private constant _TYPEHASH =
        keccak256(
            "ForwardRequest(address from,address to,address relayer,uint256 feeAmount,uint256 value,uint256 gas,uint256 nonce,bytes data)"
        );

    mapping(address => uint256) private _nonces; /**contract level nonce. different than default ethereum's */

    IERC20 public _feeToken; /**address of the ERC20 used to collect fee*/
    address public _treasury; /**address of the account used to send collected ERC20 fee*/

    event SetFeeToken(address indexed oldFeeToken, address indexed newFeeToken);

    event SetTreasury(address indexed oldTreasury, address indexed newTreasury);

    constructor(address feeToken, address treasury)
        EIP712("MinimalForwarder", "0.0.1")
    {
        _transferOwnership(_msgSender());
        setFeeToken(feeToken);
        setTreasury(treasury);
    }

    function getNonce(address relayer) public view returns (uint256) {
        return _nonces[relayer];
    }

    function verify(ForwardRequest calldata req, bytes calldata signature)
        public
        view
        returns (bool)
    {
        address signer = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    _TYPEHASH,
                    req.from,
                    req.to,
                    req.relayer,
                    req.feeAmount,
                    req.value,
                    req.gas,
                    req.nonce,
                    keccak256(req.data)
                )
            )
        ).recover(signature);
        return _nonces[req.relayer] == req.nonce && signer == req.from;
    }

    function execute(ForwardRequest calldata req, bytes calldata signature)
        public
        payable
        returns (bool, bytes memory)
    {
        require(
            verify(req, signature),
            "MinimalForwarder: signature does not match request"
        );

        if (req.feeAmount > 0) {
            uint allowance = _feeToken.allowance(_msgSender(), address(this));
            require(allowance >= req.feeAmount, "Insufficient allowance");
            _feeToken.transferFrom(_msgSender(), address(this), req.feeAmount);
        }

        _nonces[req.relayer] = req.nonce + 1;

        (bool success, bytes memory returndata) = req.to.call{
            gas: req.gas,
            value: req.value
        }(abi.encodePacked(req.data, req.from));

        // Validate that the relayer has sent enough gas for the call.
        // See https://ronan.eth.link/blog/ethereum-gas-dangers/
        if (gasleft() <= req.gas / 63) {
            // We explicitly trigger invalid opcode to consume all gas and bubble-up the effects, since
            // neither revert or assert consume all gas since Solidity 0.8.0
            // https://docs.soliditylang.org/en/v0.8.0/control-structures.html#panic-via-assert-and-error-via-require
            /// @solidity memory-safe-assembly
            assembly {
                invalid()
            }
        }

        return (success, returndata);
    }

    function getFeeToken() external view returns (address feeToken) {
        return address(_feeToken);
    }

    function setFeeToken(address newFeeToken) public onlyOwner {
        address oldFeeToken = address(_feeToken);
        _feeToken = IERC20(newFeeToken);
        emit SetFeeToken(oldFeeToken, newFeeToken);
    }

    function setTreasury(address newTreasury) public onlyOwner {
        address oldTreasury = _treasury;
        _treasury = newTreasury;
        emit SetTreasury(oldTreasury, newTreasury);
    }

    /// Withdraw ERC-20 token to owner.
    /// @param amount of tokens including decimals.
    function withdrawERC20(uint256 amount) external onlyOwner {
        IERC20(_feeToken).transfer(_treasury, amount);
    }
}