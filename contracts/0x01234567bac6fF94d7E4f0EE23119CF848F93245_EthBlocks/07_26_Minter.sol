// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "./Signature.sol";
import "./EthBlocks.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Eth Blocks Minter
 * Contract to seperate minting logic
 */
contract Minter is Ownable, VerifySignature {
    address public signer;
    address payable public beneficiary;
    EthBlocks public ethBlock;
    using SafeMath for uint256;

    constructor(
        address _signer,
        address payable _beneficiary,
        EthBlocks _ethblock
    ) {
        signer = _signer;
        beneficiary = _beneficiary;
        ethBlock = _ethblock;
    }

    function changeSigner(address _newSigner) public onlyOwner {
        signer = _newSigner;
    }

    function changeBeneficiary(address payable _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }

    function changeEthBlock(EthBlocks _ethBlock) public onlyOwner {
        ethBlock = _ethBlock;
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     * @param _blockNumber block number of the block
     * @param _blockHash bytes32 of the blockHash
     * @param _ipfsHash ipfsHash of the token URI
     * @param _price price of the token
     * @param _signature signature of keccak256(abi.encodePacked(_blockNumber, _tokenId, _ipfsHash)) signed by the signer
     */
    function mint(
        address _to,
        uint256 _blockNumber,
        bytes32 _blockHash,
        string memory _ipfsHash,
        uint256 _price,
        bytes memory _signature
    ) external payable {
        require(
            verifySig(
                _to,
                _blockNumber,
                _blockHash,
                _ipfsHash,
                _price,
                signer,
                _signature
            ),
            "EthBlocksMinter: Not a valid signature"
        );
        require(msg.value >= _price, "EthBlocksMinter: Price is low");
        uint256 remainder = msg.value.sub(_price);
        beneficiary.transfer(_price);
        ethBlock.mint(_to, _blockNumber, _blockHash, _ipfsHash);
        payable(msg.sender).transfer(remainder);
    }

    function updateToken(
        address _to,
        uint256 _blockNumber,
        bytes32 _blockHash,
        string memory _ipfsHash,
        uint256 _price,
        bytes memory _signature
    ) external payable {
        require(
            verifySig(
                _to,
                _blockNumber,
                _blockHash,
                _ipfsHash,
                _price,
                signer,
                _signature
            ),
            "EthBlocks: Not a valid signature"
        );
        require(msg.value >= _price, "EthBlocksMinter: Price is low");
        require(
            ethBlock.ownerOf(_blockNumber) == msg.sender,
            "EthBlocksMinter: update caller is not owner"
        );
        uint256 remainder = msg.value.sub(_price);
        beneficiary.transfer(_price);
        ethBlock.updateToken(_blockNumber, _blockHash, _ipfsHash);
        payable(msg.sender).transfer(remainder);
    }

    function multicall(bytes[] calldata data)
        external
        returns (bytes[] memory results)
    {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(
                data[i]
            );
            require(success);
            results[i] = result;
        }
        return results;
    }
}