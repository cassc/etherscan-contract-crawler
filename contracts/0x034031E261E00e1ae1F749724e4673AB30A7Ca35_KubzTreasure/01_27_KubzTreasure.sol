// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./Guardian/Erc721LockRegistry.sol";
import "./OPR/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "./interfaces/IBreedingInfo.sol";

// import "hardhat/console.sol";

contract KubzTreasure is
    ERC721x,
    DefaultOperatorFiltererUpgradeable,
    ReentrancyGuardUpgradeable
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    string public baseTokenURI;
    address public signer;
    mapping(uint256 => uint256) public boxRarity;
    EnumerableSet.AddressSet claimedUsers;

    mapping(uint256 => uint256) public kubzToTreasure;
    address public signerAlt;
    IERC721 public kubzContract;

    function initialize(string memory baseURI) public initializer {
        ERC721x.__ERC721x_init("Kubz Relic", "Kubz Relic");
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        DefaultOperatorFiltererUpgradeable.__DefaultOperatorFilterer_init();
        baseTokenURI = baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setAddresses(
        address signerAddress,
        address signerAltAddress,
        address kubzAddress
    ) external onlyOwner {
        signer = signerAddress;
        signerAlt = signerAltAddress;
        kubzContract = IERC721(kubzAddress);
    }

    // =============== AIR DROP ===============

    function checkValidity(bytes calldata signature, string memory action)
        public
        view
        returns (bool)
    {
        require(
            ECDSA.recover(
                ECDSA.toEthSignedMessageHash(
                    keccak256(abi.encodePacked(msg.sender, action))
                ),
                signature
            ) == signer,
            "invalid signature"
        );
        return true;
    }

    function checkValidityAlt(bytes calldata signature, string memory action)
        public
        view
        returns (bool)
    {
        require(
            ECDSA.recover(
                ECDSA.toEthSignedMessageHash(
                    keccak256(abi.encodePacked(msg.sender, action))
                ),
                signature
            ) == signerAlt,
            "invalid signature"
        );
        return true;
    }

    function claim(uint256[] calldata rarities, bytes calldata signature)
        external
    {
        require(!claimedUsers.contains(msg.sender), "Already claimed");
        string memory action = "prize-box_claim_";
        // prize-box_claim_11234
        for (uint256 i = 0; i < rarities.length; i++) {
            action = string.concat(action, Strings.toString(rarities[i]));
        }
        // console.log(action);
        checkValidity(signature, action);

        uint256 start = _nextTokenId();
        claimedUsers.add(msg.sender);
        _mint(msg.sender, rarities.length);

        for (uint256 i = 0; i < rarities.length; i++) {
            uint256 tokenId = start + i;
            require(
                ownerOf(tokenId) == msg.sender && boxRarity[tokenId] == 0,
                "Fail"
            );
            boxRarity[tokenId] = rarities[i];
        }
    }

    function kubzClaim(
        uint256 kubzTokenId,
        uint256 rarity,
        bytes calldata signature
    ) external {
        require(kubzToTreasure[kubzTokenId] == 0, "Already claimed");
        require(
            kubzContract.ownerOf(kubzTokenId) == msg.sender,
            "Not owner of kubz"
        );
        // prize-box_kubz_claim_1234,1
        string memory action = string.concat(
            "prize-box_kubz_claim_",
            Strings.toString(kubzTokenId),
            ",",
            Strings.toString(rarity)
        );

        // console.log(action);
        checkValidityAlt(signature, action);

        uint256 tokenId = _nextTokenId();

        _mint(msg.sender, 1);
        require(
            ownerOf(tokenId) == msg.sender && boxRarity[tokenId] == 0,
            "Fail"
        );
        boxRarity[tokenId] = rarity;
        kubzToTreasure[kubzTokenId] = tokenId;
    }

    function kubzClaimMultiple(
        uint256[] calldata kubzTokenIds,
        uint256[] calldata rarities,
        bytes[] calldata signatures
    ) public {
        for (uint256 i = 0; i < kubzTokenIds.length; i++) {
            uint256 kubzTokenId = kubzTokenIds[i];
            uint256 rarity = rarities[i];
            bytes calldata signature = signatures[i];

            require(kubzToTreasure[kubzTokenId] == 0, "Already claimed");
            require(
                kubzContract.ownerOf(kubzTokenId) == msg.sender,
                "Not owner of kubz"
            );
            // prize-box_kubz_claim_1234,1
            string memory action = string.concat(
                "prize-box_kubz_claim_",
                Strings.toString(kubzTokenId),
                ",",
                Strings.toString(rarity)
            );

            // console.log(action);
            checkValidityAlt(signature, action);
        }
        uint256 startTokenId = _nextTokenId();
        _mint(msg.sender, kubzTokenIds.length);
        for (uint256 i = 0; i < kubzTokenIds.length; i++) {
            uint256 kubzTokenId = kubzTokenIds[i];
            uint256 tokenId = startTokenId + i;
            uint256 rarity = rarities[i];

            require(
                ownerOf(tokenId) == msg.sender && boxRarity[tokenId] == 0,
                "Fail"
            );
            boxRarity[tokenId] = rarity;
            kubzToTreasure[kubzTokenId] = tokenId;
        }
    }

    // =============== BASE URI ===============
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (string memory)
    {
        return
            string.concat(
                super.tokenURI(_tokenId)
            );
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    // =============== MARKETPLACE CONTROL ===============
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public virtual override(ERC721x) onlyAllowedOperator(_from) {
        super.transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override(ERC721x) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // =============== MISC ===============
    function getClaimedUsersLength() external view returns (uint256) {
        return claimedUsers.length();
    }

    function getClaimedUsers(uint256 fromIdx, uint256 toIdx)
        external
        view
        returns (address[] memory)
    {
        toIdx = Math.min(toIdx, claimedUsers.length());
        address[] memory part = new address[](toIdx - fromIdx);
        for (uint256 i = 0; i < toIdx - fromIdx; i++) {
            part[i] = claimedUsers.at(i + fromIdx);
        }
        return part;
    }

    function getClaimedUsersAll() external view returns (address[] memory) {
        return claimedUsers.values();
    }

    function getKubzToTreasures(uint256[] calldata kubzTokenIds)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory part = new uint256[](kubzTokenIds.length);
        for (uint256 i = 0; i < kubzTokenIds.length; i++) {
            uint256 kubzTokenId = kubzTokenIds[i];
            part[i] = kubzToTreasure[kubzTokenId];
        }
        return part;
    }

    function getBoxRarities(uint256 fromTokenId, uint256 toTokenId)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory part = new uint256[]((toTokenId - fromTokenId) + 1);
        for (uint256 tokenId = fromTokenId; tokenId <= toTokenId; tokenId++) {
            uint256 i = tokenId - fromTokenId;
            part[i] = boxRarity[tokenId];
        }
        return part;
    }

    function getBoxRaritiesOf(uint256[] calldata tokenIds)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory part = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            part[i] = boxRarity[tokenId];
        }
        return part;
    }
}