pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../library/ERC721Buyable.sol";
import "../interfaces/IBasis.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Basis is IBasis, ERC721Buyable {
    using Strings for uint256;

    string internal baseURI;
    uint256 internal lastTokenId_;
    string public contractURI;

    event SetContractURI(string contractURI);
    event SetBaseURI(string baseUri);

    constructor(
        address _proxyRegistry,
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        string memory _contractURI,
        address _paymentToken
    ) ERC721(_name, _symbol) ERC721Buyable(_paymentToken, _name, "1.0.0") {
        baseURI = _baseURI;
        contractURI = _contractURI;
        proxyRegistry = _proxyRegistry;
    }

    function setContractURI(string memory _contractURI)
    external
    override
    onlyOwner
    {
        contractURI = _contractURI;

        emit SetContractURI(_contractURI);
    }

    function setBaseURI(string memory _baseUri) external override onlyOwner {
        baseURI = _baseUri;

        emit SetBaseURI(_baseUri);
    }

    /**
     * @dev Get a `tokenURI`
     * @param `_tokenId` an id whose `tokenURI` will be returned
     * @return `tokenURI` string
     */
    function tokenURI(uint256 _tokenId)
    public
    view
    override
    returns (string memory)
    {
        require(_exists(_tokenId), "Basis: URI query for nonexistent token");

        // Concatenate the tokenID to the baseURI, token symbol and token id
        return string(abi.encodePacked(baseURI, _tokenId.toString()));
    }

    function totalSupply()
    external
    view
    override
    returns (uint256)
    {
        return lastTokenId_;
    }

    function _isContract(address _addr) internal returns (bool _isContract){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}