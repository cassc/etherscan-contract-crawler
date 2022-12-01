// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./DefaultOperatorFilterer.sol";
import "./interfaces/IOmnibus.sol";

/// @title Vogu Rescue
/// @author Atlas C.O.R.P.
contract VoguRescue is ERC721, DefaultOperatorFilterer, Ownable {
    enum RescueState {
        OFF,
        MIGRATION,
        ACTIVE
    }

    IOmnibus public immutable captorContract;
    RescueState public rescueState;
    string public baseURI;
    uint256 public counter;
    uint256 public constant maxSupply = 304;

    mapping(uint256 => bool) public tokensClaimed;

    event TokenUsedForClaim(uint256 indexed tokenId);

    constructor(
        string memory _name,
        string memory _symbol,
        address _captorContract,
        string memory _uri
    ) ERC721(_name, _symbol) {
        captorContract = IOmnibus(_captorContract);
        baseURI = _uri;
        rescueState = RescueState.MIGRATION;
        _safeMint(0xb963fa652274e887E7Ab9876f436e054Dfb3C3cD, 0);
    }

    /// @notice mints new Vogu token and burns tokenId on old Vogu contract
    /// @param _tokenId is the Id of the NFT
    function rescue(uint256 _tokenId) external {
        require(
            rescueState == RescueState.MIGRATION,
            "rescue: Rescue State must be MIGRATION"
        );
        require(
            captorContract.ownerOf(_tokenId) == msg.sender,
            "rescue: caller must own token on captor contract"
        );
        require(!tokensClaimed[_tokenId], "rescue: token already claimed");
        tokensClaimed[_tokenId] = true;

        emit TokenUsedForClaim(_tokenId);

        _safeMint(msg.sender, ++counter);

        captorContract.burn(_tokenId);
    }

    /// @notice mints new vogu tokens and burns old tokenId's on old contract
    /// @param _tokenIds are the Id's of the NFT's
    function rescueBatch(uint256[] calldata _tokenIds) external {
        require(
            rescueState == RescueState.MIGRATION,
            "rescueBatch: Rescue State must be MIGRATION"
        );
        uint256 i;
        for (; i < _tokenIds.length; ) {
            require(
                captorContract.ownerOf(_tokenIds[i]) == msg.sender,
                "rescueBatch: caller must own token on captor contract"
            );
            require(
                !tokensClaimed[_tokenIds[i]],
                "rescueBatch: token already claimed"
            );
            tokensClaimed[_tokenIds[i]] = true;

            _safeMint(msg.sender, ++counter);

            emit TokenUsedForClaim(_tokenIds[i]);

            unchecked {
                ++i;
            }
        }
        captorContract.burnBatch(_tokenIds);
    }

    /// @param _amount is the amount of tokens owner wants to mint
    function mintReserveTokens(uint256 _amount) external onlyOwner {
        require(
            rescueState == RescueState.ACTIVE,
            "mintReserveTokens: Contract must be ACTIVE to mint reserve"
        );

        require(_amount > 0, "mintReserveTokens: Cannot mint reserve 0 tokens");

        require(
            _amount + counter <= maxSupply,
            "mintReserveTokens: Insufficient supply remaining for purchase"
        );

        uint256 i = 0;
        for (; i < _amount; ) {
            unchecked {
                _safeMint(msg.sender, ++counter);
                ++i;
            }
        }
    }

    /// @param _rescueState is the state of the contract either OFF or ACTIVE
    function setRescueState(RescueState _rescueState) external onlyOwner {
        rescueState = _rescueState;
    }

    /// @param _URI is the IPFS link
    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseURI;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}