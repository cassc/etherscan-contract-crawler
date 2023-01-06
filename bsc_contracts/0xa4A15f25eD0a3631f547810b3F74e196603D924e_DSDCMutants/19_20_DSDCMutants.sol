// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Base.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IToxicBeer {
    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface IDSDC {
    function ownerOf(uint256) external returns (address);
}

contract DSDCMutants is ERC721Base, ReentrancyGuard {
    using SafeMath for uint256;

    event MutationStarted(address owner, uint256[] tokenIds, uint256 timeStamp);
    event MutationComplete(
        address owner,
        uint256[] tokenIds,
        uint256 timeStamp
    );

    IDSDC public immutable dsdc;

    IToxicBeer public immutable toxicbeer;

    IERC20 public immutable stink;

    bool public mutationIsActive;

    uint256 public price = 15000 * 10**18;

    string private baseURI;

    uint256 public mutationDuration = 86400;

    mapping(address => uint256) public userMutationDuration;
    mapping(address => uint256[]) public userDsdcToBeMutated;
    mapping(uint256 => bool) public dsdcBeingMutated;

    constructor(
        address _dsdc,
        address _toxicbeer,
        address _stink
    ) ERC721Base("DSDC Mutants", "DSDCM") {
        dsdc = IDSDC(_dsdc);
        toxicbeer = IToxicBeer(_toxicbeer);
        stink = IERC20(_stink);
        _safeMint(address(0xd72349C480616D1CE11fBB21F317C357CEeE330d), 4526);
    }

    function claimMutant() external nonReentrant {
        require(
            userMutationDuration[msg.sender] + mutationDuration <=
                block.timestamp,
            "Mutation still ongoing..."
        );

        uint256[] memory userMutants = userDsdcToBeMutated[msg.sender];
        delete userDsdcToBeMutated[msg.sender];

        uint256 _nMutants = userMutants.length;
        for (uint256 i = 0; i < _nMutants; ) {
            _safeMint(msg.sender, userMutants[i]);
            dsdcBeingMutated[userMutants[i]] = false;
            unchecked {
                ++i;
            }
        }
        emit MutationComplete(msg.sender, userMutants, block.timestamp);
    }

    function consumeToxicBeer(uint256[] calldata tokenIds)
        external
        nonReentrant
    {
        require(mutationIsActive, "Mutation not started yet");

        uint256 amount = tokenIds.length;
        uint256[] memory userToxicBeers = toxicbeer.walletOfOwner(msg.sender);

        require(amount > 0, "Invalid amount : min is 1");
        require(amount <= 20, "Invalid amount : max is 20");
        require(amount <= userToxicBeers.length, "Not enough beers");

        require(
            userDsdcToBeMutated[msg.sender].length == 0,
            "You already have a mutation pending !"
        );

        stink.transferFrom(msg.sender, address(this), price * amount);

        for (uint256 i = 0; i < amount; ) {
            _prepareForMutation(tokenIds[i]);
            _burnToxicBeer(userToxicBeers[i]);
            unchecked {
                ++i;
            }
        }

        userMutationDuration[msg.sender] = block.timestamp;

        emit MutationStarted(msg.sender, tokenIds, block.timestamp);
    }

    function withdrawStink() external onlyOwner {
        stink.transfer(msg.sender, stink.balanceOf(address(this)));
    }

    function startMutations() external onlyOwner {
        mutationIsActive = true;
    }

    function pauseMutations() external onlyOwner {
        mutationIsActive = false;
    }

    function getUserDsdcsToBeMutated(address userAddress)
        external
        view
        returns (uint256[] memory)
    {
        return userDsdcToBeMutated[userAddress];
    }

    function dsdcCanMutate(uint256 tokenId) external view returns (bool) {
        return !_exists(tokenId) && !dsdcBeingMutated[tokenId];
    }

    function dsdcsCanMutate(uint256[] calldata tokenIds)
        external
        view
        returns (bool[] memory transformable)
    {
        transformable = new bool[](tokenIds.length);
        for (uint256 index = 0; index < tokenIds.length; index++) {
            transformable[index] =
                !_exists(tokenIds[index]) &&
                !dsdcBeingMutated[tokenIds[index]];
        }
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMutationDuration(uint256 _newDuration) external onlyOwner {
        mutationDuration = _newDuration;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _prepareForMutation(uint256 tokenId) internal {
        require(
            dsdc.ownerOf(tokenId) == msg.sender,
            "Must own the DSDC to mutate"
        );
        require(
            !_exists(tokenId) && !dsdcBeingMutated[tokenId],
            "DSDC already mutated or is being mutated"
        );
        userDsdcToBeMutated[msg.sender].push(tokenId);
        dsdcBeingMutated[tokenId] = true;
    }

    function _burnToxicBeer(uint256 tokenId) internal {
        toxicbeer.transferFrom(
            msg.sender,
            address(0x000000000000000000000000000000000000dEaD),
            tokenId
        );
    }
}