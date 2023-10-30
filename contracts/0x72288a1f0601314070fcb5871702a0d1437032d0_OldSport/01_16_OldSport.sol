// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "hardhat/console.sol";

contract OldSport is ERC721, ERC2981, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter public totalSupply;

    enum Phase {
        TEAM,
        PRIVATE,
        TOKENGATE,
        PREMINT,
        PUBLIC
    }

    uint256 public constant MAX_TOKENS = 1920;
    uint256 public constant PRICE = 1 ether;
    uint96 public royaltyFee;
    address public royaltyAddress;

    Phase public phase;
    mapping(Phase => bytes32) public merkleRoot;

    string private baseTokenURI;

    constructor() ERC721("OldSport", "OLDSPORT") {
        royaltyAddress = owner();
        royaltyFee = 1000;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    /**
     * *** PUBLIC ***
     *
     * @notice mint 1 nft
     * @param data | proof
     */
    function mint(bytes32[] calldata data) external payable virtual {
        if (phase == Phase.TEAM) {
            require(msg.sender == owner(), "OldSport#mint: ONLY_OWNER");

            for (uint256 i = 0; i < uint256(data[0]); i++) {
                _mint();
            }
        } else {
            require(msg.value == PRICE, "OldSport#mint: INCORRECT_VALUE");

            if (phase == Phase.PRIVATE || phase == Phase.TOKENGATE || phase == Phase.PREMINT) {
                require(
                    MerkleProof.verify(data, merkleRoot[phase], keccak256(abi.encodePacked(msg.sender))),
                    "OldSport#mint: INVALID_ADDRESS"
                );
            } else {
                require(phase == Phase.PUBLIC, "OldSport#mint: PUBLIC_MINT_CLOSED");
            }

            _mint();
        }
    }

    /**
     * *** ONLY OWNER ***
     *
     * @notice set the base token uri
     * @param _baseTokenURI | base token URI
     */
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /**
     * *** ONLY OWNER ***
     *
     * @notice set the minting phase
     * @param _phase | enum minting phase
     */
    function setPhase(Phase _phase) external onlyOwner {
        phase = _phase;
    }

    /**
     * *** ONLY OWNER ***
     *
     * @notice withdraw contract eth
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    /**
     * *** ONLY OWNER ***
     *
     * @notice update royalty fee
     */
    function setRoyaltyFee(uint96 fee) external onlyOwner {
        royaltyFee = fee;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    /**
     * *** ONLY OWNER ***
     *
     * @notice update royalty address
     */
    function setRoyaltyAddress(address addr) external onlyOwner {
        royaltyAddress = addr;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    /**
     * *** ONLY OWNER ***
     *
     * @notice set merkle root for phase
     *
     * @param _phase | the phase to set the merkle root for
     * @param _merkleRoot | the merkle root
     */
    function setMerkleRoot(Phase _phase, bytes32 _merkleRoot) public onlyOwner {
        merkleRoot[_phase] = _merkleRoot;
    }

    /**
     * *** PRIVATE ***
     *
     * @notice mint 1 token
     */
    function _mint() private {
        totalSupply.increment();

        uint256 tokenId = totalSupply.current();

        require(tokenId <= MAX_TOKENS, "OldSport#_mint: EXCEEDS_MAX_TOKENS");

        _mint(msg.sender, tokenId);
    }

    /**
     * *** INTERNAL ***
     *
     * @notice set the minting phase
     * @return baseTokenURI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * *** INTERNAL ***
     *
     * @notice token cannot be transferred to existing owner
     * @dev See {ERC721-beforeTokenTransfer}
     */
    function _beforeTokenTransfer(
        address,
        address to,
        uint256
    ) internal view override {
        if (to != owner()) {
            require(balanceOf(to) == 0, "OldSport#_beforeTokenTransfer: LIMIT_ONE");
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}