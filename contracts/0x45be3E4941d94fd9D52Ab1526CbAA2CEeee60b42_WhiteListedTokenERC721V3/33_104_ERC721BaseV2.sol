// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/ERC721Burnable.sol";
import "../HasContractURI.sol";
import "../HasSecondarySale.sol";
import "../../roles/MinterRole.sol";
import "../../libs/RoyaltyLibrary.sol";
import "../Royalty.sol";

/**
 * @title Full ERC721 Token with support for baseURI
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
abstract contract ERC721BaseV2 is
HasSecondarySale,
HasContractURI,
ERC721Burnable,
MinterRole,
Royalty
{
    /// @dev sale is primary or secondary
    mapping(uint256 => bool) public isSecondarySale;

    /*
     * bytes4(keccak256('MINT_WITH_ADDRESS')) == 0xe37243f2
     */
    bytes4 private constant _INTERFACE_ID_MINT_WITH_ADDRESS = 0xe37243f2;


    /**
     * @dev Constructor function
     */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory contractURI,
        string memory _baseURI
    ) public HasContractURI(contractURI) ERC721(_name, _symbol) {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_MINT_WITH_ADDRESS);
        _setBaseURI(_baseURI);
    }

    function checkSecondarySale(uint256 _tokenId) public view override returns (bool) {
        return isSecondarySale[_tokenId];
    }

    function setSecondarySale(uint256 _tokenId) public override {
        isSecondarySale[_tokenId] = true;
    }

    function _mint(
        address _to,
        uint256 _tokenId,
        RoyaltyLibrary.RoyaltyShareDetails[] memory _royaltyShares,
        string memory _uri,
        uint256 _royaltyBps,
        RoyaltyLibrary.Strategy _royaltyStrategy
    ) internal {
        require(_exists(_tokenId) == false, "ERC721: Token is already minted");
        require(bytes(_uri).length > 0, "ERC721: Uri should be set");

        _mint(_to, _tokenId);
        _setTokenURI(_tokenId, _uri);
        uint256 sumRoyaltyShareBps;
        for (uint256 i = 0; i < _royaltyShares.length; i++) {
            sumRoyaltyShareBps = sumRoyaltyShareBps.add(_royaltyShares[i].value);
        }

        if(_royaltyStrategy == RoyaltyLibrary.Strategy.ROYALTY_STRATEGY) {
            require(
                sumRoyaltyShareBps <= 10**4,
                "ERC721: Total fee bps should not exceed 10000"
            );
            _setRoyalty(_tokenId, sumRoyaltyShareBps, RoyaltyLibrary.Strategy.ROYALTY_STRATEGY);
        } else if (_royaltyStrategy == RoyaltyLibrary.Strategy.PROFIT_DISTRIBUTION_STRATEGY) {
            require(
                sumRoyaltyShareBps == 10**4,
                "ERC721: Total fee bps should be 10000"
            );
            _setRoyalty(_tokenId, _royaltyBps,  RoyaltyLibrary.Strategy.PROFIT_DISTRIBUTION_STRATEGY);
        }else{
            revert("ERC721: Royalty option does not exist");
        }
        _addRoyaltyShares(_tokenId, _royaltyShares);
    }

    function setBaseURI(string memory _baseURI) public onlyAdmin {
        _setBaseURI(_baseURI);
    }

    function setContractURI(string memory _contractURI) public onlyAdmin {
        _setContractURI(_contractURI);
    }
}