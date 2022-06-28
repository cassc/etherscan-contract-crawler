// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OVLCars is ERC721, Ownable {
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    uint256 public constant MAX_SUPPLY = 5396;
    Counters.Counter public totalSupply;

    string private baseURI = "https://metadata.overleague.com/eth/";
    string private baseContractURI =
        "https://metadata.overleague.com/eth/contract";

    mapping(address => uint256) public nonces;

    // Mapping from owner address to token ID
    mapping(address => uint256[]) private tokenIds;

    // Mapping from tokenId to ownerIndex
    mapping(uint256 => uint256) private tokenIdIndexs;

    // Mapping from owner address to token ID
    mapping(address => uint256[]) private claimedTokenIds;

    constructor() ERC721("Overleague Car", "OVL CAR") {
        //
    }

    function mint(
        uint256 _tokenId,
        uint256 _nonce,
        bytes calldata signature
    ) external {
        require(
            totalSupply.current() < MAX_SUPPLY,
            "Total supply limit reached"
        );
        address _sender = _msgSender();
        bytes32 _ethSignedMessageHash = keccak256(
            abi.encode(_tokenId, _sender, _nonce)
        ).toEthSignedMessageHash();
        nonces[_sender]++;
        // check signature
        require(
            _ethSignedMessageHash.recover(signature) == owner(),
            "OVLCar: unauthorize"
        );
        // mint car
        _safeMint(_sender, _tokenId);
        totalSupply.increment();
    }

    /**
     * Gets token ids claimed by owner
     */
    function getTokensClaimedByOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        return claimedTokenIds[_owner];
    }

    /**
     * Gets token ids for the specific owner
     */
    function getTokensByOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        return tokenIds[_owner];
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _baseUri) public onlyOwner {
        baseContractURI = _baseUri;
    }

    function setContractURI(string memory _baseUri) public onlyOwner {
        baseContractURI = _baseUri;
    }

    /**
     * Opensea.io: contract-level metadata
     * https://docs.opensea.io/docs/contract-level-metadata
     */
    function contractURI() public view returns (string memory) {
        return baseContractURI;
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
        // Mint.
        if (from == address(0)) {
            claimedTokenIds[to].push(tokenId);
        }
        // Transfer or burn.
        else {
            // Swap and pop.
            uint256[] storage ids = tokenIds[from];
            uint256 index = tokenIdIndexs[tokenId];
            uint256 lastId = ids[ids.length - 1];
            ids[index] = lastId;
            ids.pop();
            // Update index.
            tokenIdIndexs[lastId] = index;
        }

        // Burn.
        if (to == address(0)) {
            delete tokenIdIndexs[tokenId];
        }
        // Transfer or mint.
        else {
            uint256[] storage ids = tokenIds[to];
            tokenIdIndexs[tokenId] = ids.length;
            ids.push(tokenId);
        }
    }
}