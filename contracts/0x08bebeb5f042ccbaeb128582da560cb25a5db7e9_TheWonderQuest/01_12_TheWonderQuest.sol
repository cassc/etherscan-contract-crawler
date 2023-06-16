//                                    _______ _    _ ______
//                                   |__   __| |  | |  ____|
//                                      | |  | |__| | |__
//                                      | |  |  __  |  __|
//                                      | |  | |  | | |____
//     __          ______  _   _ _____  |_|__|_|__|_|______| _    _ ______  _____ _______
//     \ \        / / __ \| \ | |  __ \|  ____|  __ \ / __ \| |  | |  ____|/ ____|__   __|
//      \ \  /\  / / |  | |  \| | |  | | |__  | |__) | |  | | |  | | |__  | (___    | |
//       \ \/  \/ /| |  | | . ` | |  | |  __| |  _  /| |  | | |  | |  __|  \___ \   | |
//        \  /\  / | |__| | |\  | |__| | |____| | \ \| |__| | |__| | |____ ____) |  | |
//         \/  \/   \____/|_| \_|_____/|______|_|__\_\\___\_\\____/|______|_____/   |_|
//                                      ______ / _ \ ______
//    ______ ______ ______ ______ _____|______| | | |______|_____ ______ ______ ______ ______
//   |______|______|______|______|______|_____| | | |_____|______|______|______|______|______|
//                                     |______| |_| |______|
//                                             \___/
//
//

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";

contract TheWonderQuest is ERC721 {
    event Hatch(address indexed from, uint256 indexed tokenId);

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier onlyCollaborator() {
        bool isCollaborator = false;
        for (uint256 i; i < collaborators.length; i++) {
            if (collaborators[i].addr == msg.sender) {
                isCollaborator = true;

                break;
            }
        }

        require(
            owner() == _msgSender() || isCollaborator,
            "Ownable: caller is not the owner nor a collaborator"
        );

        _;
    }

    modifier claimStarted() {
        require(
            startClaimDate != 0 && startClaimDate <= block.timestamp,
            "You are too early"
        );

        _;
    }

    modifier hatchStarted() {
        require(
            startHatchDate != 0 && startHatchDate <= block.timestamp,
            "You are too early"
        );

        _;
    }

    struct Collaborators {
        address addr;
        uint256 cut;
    }

    uint256 private startClaimDate = 1627250400;
    uint256 private startHatchDate = 1627855200;
    uint256 private claimPrice = 88800000000000000;
    uint256 private totalTokens = 10000;
    uint256 private totalMintedTokens = 0;
    uint256 private maxClaimsPerWallet = 10;
    uint128 private basisPoints = 10000;
    string private baseURI =
        "https://dragon-eggs.s3.ap-southeast-2.amazonaws.com/";

    mapping(address => uint256) private claimedEggsPerWallet;
    mapping(uint256 => bool) private hatchedEggs;

    uint16[] availableEggs;
    Collaborators[] private collaborators;

    constructor() ERC721("TheWonderQuest", "TWQ") {}

    // ONLY OWNER

    /**
     * Sets the collaborators of the project with their cuts
     */
    function addCollaborators(Collaborators[] memory _collaborators)
        external
        onlyOwner
    {
        require(collaborators.length == 0, "Collaborators were already set");

        uint128 totalCut;
        for (uint256 i; i < _collaborators.length; i++) {
            collaborators.push(_collaborators[i]);
            totalCut += uint128(_collaborators[i].cut);
        }

        require(totalCut == basisPoints, "Total cut does not add to 100%");
    }

    // ONLY COLLABORATORS

    /**
     * @dev Allows to withdraw the Ether in the contract and split it among the collaborators
     */
    function withdraw() external onlyCollaborator {
        uint256 totalBalance = address(this).balance;

        for (uint256 i; i < collaborators.length; i++) {
            payable(collaborators[i].addr).transfer(
                mulScale(totalBalance, collaborators[i].cut, basisPoints)
            );
        }
    }

    /**
     * @dev Sets the base URI for the API that provides the NFT data.
     */
    function setBaseTokenURI(string memory _uri) external onlyCollaborator {
        baseURI = _uri;
    }

    /**
     * @dev Sets the claim price for each egg
     */
    function setClaimPrice(uint256 _claimPrice) external onlyCollaborator {
        claimPrice = _claimPrice;
    }

    /**
     * @dev Populates the available eggs
     */
    function addAvailableEggs(uint16 from, uint16 to)
        external
        onlyCollaborator
    {
        for (uint16 i = from; i <= to; i++) {
            availableEggs.push(i);
        }
    }

    /**
     * @dev Removes a chosen egg from the available list
     */
    function removeEggsFromAvailableEggs(uint16 tokenId)
        external
        onlyCollaborator
    {
        for (uint16 i; i <= availableEggs.length; i++) {
            if (availableEggs[i] != tokenId) {
                continue;
            }

            availableEggs[i] = availableEggs[availableEggs.length - 1];
            availableEggs.pop();

            break;
        }
    }

    /**
     * @dev Allow devs to hand pick some eggs before the available eggs list is created
     */
    function allocateTokens(uint256[] memory tokenIds)
        external
        onlyCollaborator
    {
        require(availableEggs.length == 0, "Available eggs are already set");

        _batchMint(msg.sender, tokenIds);

        totalMintedTokens += tokenIds.length;
    }

    /**
     * @dev Collaborators can hatch their eggs before the hatch date
     */
    function devHatchEggs(uint256[] memory tokenIds) external onlyCollaborator {
        for (uint256 i; i < tokenIds.length; i++) {
            require(
                ownerOf(tokenIds[i]) == msg.sender,
                "You can only hatch your own eggs"
            );

            require(
                hatchedEggs[tokenIds[i]] == false,
                "Egg is already hatched"
            );

            hatchedEggs[tokenIds[i]] = true;

            emit Hatch(msg.sender, tokenIds[i]);
        }
    }

    /**
     * @dev Sets the date that users can start claiming eggs
     */
    function setStartClaimDate(uint256 _startClaimDate)
        external
        onlyCollaborator
    {
        startClaimDate = _startClaimDate;
    }

    /**
     * @dev Sets the date that users can start hatching eggs
     */
    function setStartHatchDate(uint256 _startHatchDate)
        external
        onlyCollaborator
    {
        startHatchDate = _startHatchDate;
    }

    /**
     * @dev Checks if an egg is in the available list
     */
    function isEggAvailable(uint16 tokenId)
        external
        view
        onlyCollaborator
        returns (bool)
    {
        for (uint16 i; i < availableEggs.length; i++) {
            if (availableEggs[i] == tokenId) {
                return true;
            }
        }

        return false;
    }

    /**
     * @dev Give random eggs to the provided addresses
     */
    function devClaimEggs(address[] memory addresses)
        external
        onlyCollaborator
    {
        require(
            availableEggs.length >= addresses.length,
            "No eggs left to be claimed"
        );
        totalMintedTokens += addresses.length;

        for (uint256 i; i < addresses.length; i++) {
            _mint(addresses[i], getEggToBeClaimed());
        }
    }

    /**
     * @dev Give random eggs to the provided address
     */
    function devClaimEggsToAddress(address _address, uint256 amount)
        external
        onlyCollaborator
    {
        require(availableEggs.length >= amount, "No eggs left to be claimed");
        totalMintedTokens += amount;

        uint256[] memory tokenIds = new uint256[](amount);

        for (uint256 i; i < amount; i++) {
            tokenIds[i] = getEggToBeClaimed();
        }

        _batchMint(_address, tokenIds);
    }

    // END ONLY COLLABORATORS

    /**
     * @dev Claim a single egg
     */
    function claimEgg() external payable callerIsUser claimStarted {
        require(msg.value >= claimPrice, "Not enough Ether to claim an egg");

        require(
            claimedEggsPerWallet[msg.sender] < maxClaimsPerWallet,
            "You cannot claim more eggs"
        );

        require(availableEggs.length > 0, "No eggs left to be claimed");

        claimedEggsPerWallet[msg.sender]++;
        totalMintedTokens++;

        _mint(msg.sender, getEggToBeClaimed());
    }

    /**
     * @dev Claim up to 10 eggs at once
     */
    function claimEggs(uint256 amount)
        external
        payable
        callerIsUser
        claimStarted
    {
        require(
            msg.value >= claimPrice * amount,
            "Not enough Ether to claim the eggs"
        );

        require(
            claimedEggsPerWallet[msg.sender] + amount <= maxClaimsPerWallet,
            "You cannot claim more eggs"
        );

        require(availableEggs.length >= amount, "No eggs left to be claimed");

        uint256[] memory tokenIds = new uint256[](amount);

        claimedEggsPerWallet[msg.sender] += amount;
        totalMintedTokens += amount;

        for (uint256 i; i < amount; i++) {
            tokenIds[i] = getEggToBeClaimed();
        }

        _batchMint(msg.sender, tokenIds);
    }

    /**
     * @dev Hatches an egg
     */
    function hatchEgg(uint256 tokenId) external callerIsUser hatchStarted {
        require(
            ownerOf(tokenId) == msg.sender,
            "You can only hatch your own eggs"
        );

        require(hatchedEggs[tokenId] == false, "Egg is already hatched");

        hatchedEggs[tokenId] = true;

        emit Hatch(msg.sender, tokenId);
    }

    /**
     * @dev Hatches multiple eggs
     */
    function hatchEggs(uint256[] memory tokenIds)
        external
        callerIsUser
        hatchStarted
    {
        for (uint256 i; i < tokenIds.length; i++) {
            require(
                ownerOf(tokenIds[i]) == msg.sender,
                "You can only hatch your own eggs"
            );

            require(
                hatchedEggs[tokenIds[i]] == false,
                "Egg is already hatched"
            );

            hatchedEggs[tokenIds[i]] = true;

            emit Hatch(msg.sender, tokenIds[i]);
        }
    }

    /**
     * @dev Returns whether a egg has hateched and become a dragon or not
     */
    function hasHatched(uint256 tokenId) external view returns (bool) {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );

        return hatchedEggs[tokenId];
    }

    /**
     * @dev Returns the tokenId by index
     */
    function tokenByIndex(uint256 tokenId) external view returns (uint256) {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );

        return tokenId;
    }

    /**
     * @dev Returns the base URI for the tokens API.
     */
    function baseTokenURI() external view returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Returns how many eggs are still available to be claimed
     */
    function getAvailableEggs() external view returns (uint256) {
        return availableEggs.length;
    }

    /**
     * @dev Returns the claim price
     */
    function getClaimPrice() external view returns (uint256) {
        return claimPrice;
    }

    /**
     * @dev Returns the total supply
     */
    function totalSupply() external view virtual returns (uint256) {
        return totalMintedTokens;
    }

    // Private and Internal functions

    /**
     * @dev Returns a random available egg to be claimed
     */
    function getEggToBeClaimed() private returns (uint256) {
        uint256 random = _getRandomNumber(availableEggs.length);
        uint256 tokenId = uint256(availableEggs[random]);

        availableEggs[random] = availableEggs[availableEggs.length - 1];
        availableEggs.pop();

        return tokenId;
    }

    /**
     * @dev Generates a pseudo-random number.
     */
    function _getRandomNumber(uint256 _upper) private view returns (uint256) {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    availableEggs.length,
                    blockhash(block.number - 1),
                    block.coinbase,
                    block.difficulty,
                    msg.sender
                )
            )
        );

        return random % _upper;
    }

    /**
     * @dev See {ERC721}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mulScale(
        uint256 x,
        uint256 y,
        uint128 scale
    ) internal pure returns (uint256) {
        uint256 a = x / scale;
        uint256 b = x % scale;
        uint256 c = y / scale;
        uint256 d = y % scale;

        return a * c * scale + a * d + b * c + (b * d) / scale;
    }
}