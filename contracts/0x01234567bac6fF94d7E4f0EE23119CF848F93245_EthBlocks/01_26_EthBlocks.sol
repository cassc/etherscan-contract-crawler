// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "./Minter.sol";
import "./@rarible/royalties/contracts/LibPart.sol";

/**
 * @title Eth Blocks
 * ETHB - a contract for creating Ethereum block NFTs
 */
contract EthBlocks is ERC721Tradable {
    address payable public royaltyAddress;
    uint96 public royaltyBasisPoints;
    Minter public minter;
    mapping(uint256 => bytes32) public blockHashes;
    using SafeMath for uint256;
    event Updated(uint256 tokenId, string url);

    /**
     * @dev Throws if called by any account other than the authorized minter.
     */
    modifier onlyMinter() {
        require(
            address(minter) == _msgSender(),
            "EthBlocks: caller is not the minter"
        );
        _;
    }

    constructor(
        address _proxyRegistryAddress,
        address payable _royaltyAddress,
        uint96 _royaltyBasisPoints,
        string memory _name,
        string memory _symbol
    ) ERC721Tradable(_name, _symbol, _proxyRegistryAddress) {
        royaltyAddress = _royaltyAddress;
        royaltyBasisPoints = _royaltyBasisPoints;
    }

    function contractURI() public pure returns (string memory) {
        return "https://ethblocksdata.mewapi.io/contract/meta";
    }

    function changeMinter(Minter _minter) public onlyOwner {
        minter = _minter;
    }

    function changeRoyaltyAddress(address payable _royaltyAddress)
        public
        onlyOwner
    {
        royaltyAddress = _royaltyAddress;
    }

    function changeRoyaltyBasisPoints(uint96 _basisPoints) public onlyOwner {
        royaltyBasisPoints = _basisPoints;
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     * @param _blockNumber block number of the block
     * @param _blockHash bytes32 of the blockHash
     * @param _ipfsHash ipfsHash of the token URI
     */

    function mint(
        address _to,
        uint256 _blockNumber,
        bytes32 _blockHash,
        string memory _ipfsHash
    ) external onlyMinter {
        _safeMint(_to, _blockNumber);
        _setTokenURI(_blockNumber, _ipfsHash);
        blockHashes[_blockNumber] = _blockHash;
        emit RoyaltiesSet(_blockNumber, _getRoyalties());
    }

    /**
     * @dev Updates a token to a new TokenURI.
     * @param _blockNumber block number of the block
     * @param _blockHash bytes32 of the blockHash
     * @param _ipfsHash ipfsHash of the token URI
     */

    function updateToken(
        uint256 _blockNumber,
        bytes32 _blockHash,
        string memory _ipfsHash
    ) external onlyMinter {
        _setTokenURI(_blockNumber, _ipfsHash);
        blockHashes[_blockNumber] = _blockHash;
        emit Updated(_blockNumber, tokenURI(_blockNumber));
    }

    /**
     * @dev Rarible Royalties.
     * @param //_blockNumber token id
     */

    function getRaribleV2Royalties(
        uint256 /*_blockNumber*/
    ) public view override returns (LibPart.Part[] memory) {
        return _getRoyalties();
    }

    /**
     * @dev ERC2981 for mintable.
     * @param //_blockNumber block number of the block
     * @param _salePrice sale price of NFT
     */

    function royaltyInfo(
        uint256, /*_blockNumber*/
        uint256 _salePrice
    ) external view returns (address receiver, uint256 royaltyAmount) {
        LibPart.Part[] memory _royalties = _getRoyalties();
        if (_royalties.length > 0) {
            return (
                _royalties[0].account,
                (_salePrice * _royalties[0].value) / 10000
            );
        }
        return (address(0), 0);
    }

    function _getRoyalties() internal view returns (LibPart.Part[] memory) {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = royaltyBasisPoints;
        _royalties[0].account = royaltyAddress;
        return _royalties;
    }

    function getOwnersAllTokens(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 balance = balanceOf(_owner);
        uint256[] memory tokens = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            tokens[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokens;
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