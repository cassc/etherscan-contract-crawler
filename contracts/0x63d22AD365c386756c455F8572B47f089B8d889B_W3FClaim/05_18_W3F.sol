//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract W3F is IERC721Metadata, ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 private constant MAX_SUPPLY = 1500;
    uint256 private constant MAX_SUPPLY_RAINBOW = 11;
    uint256 private constant W3FMAX_SUPPLY_GOLD = 102;
    uint256 private constant MAX_SUPPLY_SILVER = 499;
    uint256 private constant MAX_MINT_COUNT = 3;
    uint256 public price = 0.21 ether;
    uint256 public commissionBasePoints = 2500; // 25%
    string public notRevealedUri;
    string public baseURI;
    bool public paused = false;
    bool public revealed = false;
    uint256 private availablePassesCount = MAX_SUPPLY;
    mapping(uint => uint) private availablePasses;
    mapping(address => uint256) private mintedCount;

    event Referral(address indexed referrer, address indexed referred);
    event Commission(address indexed recipient, address indexed referred, uint256 amount, uint256 count);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) public ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    function setCommissionBasePoints(uint256 _newCommissionBasePoints) external onlyOwner {
        require(_newCommissionBasePoints <= 10000);
        commissionBasePoints = _newCommissionBasePoints;
    }

    function passLevelOf(address _owner) external view virtual returns (string memory) {
        uint256[] memory tokenIds = walletOf(_owner);
        require(tokenIds.length > 0, "W3F: Owner has an empty wallet.");

        // The lower the lowest owned token ID, the better the pass level.
        uint256 lowestTokenId = tokenIds[0];
        if (tokenIds.length > 1) {
            for (uint256 i = 1; i < tokenIds.length; i++) {
                if (tokenIds[i] < lowestTokenId) {
                    lowestTokenId = tokenIds[i];

                    if (lowestTokenId <= MAX_SUPPLY_RAINBOW) break;
                }
            }
        }

        require(lowestTokenId > 0 && lowestTokenId <= MAX_SUPPLY, "W3F: Account has no valid pass.");

        if (lowestTokenId <= MAX_SUPPLY_RAINBOW) {
            return "Rainbow";
        } else if (lowestTokenId <= MAX_SUPPLY_RAINBOW + W3FMAX_SUPPLY_GOLD) {
            return "Gold";
        } else if (lowestTokenId <= MAX_SUPPLY_RAINBOW + W3FMAX_SUPPLY_GOLD + MAX_SUPPLY_SILVER) {
            return "Silver";
        }

        return "Bronze";
    }

    // The 11 rainbow passes are not included here
    function mintedBy(address _minter) external view returns (uint256) {
        require(_minter != address(0), "Zero address not allowed.");

        return mintedCount[_minter];
    }

    function mintRainbowPasses(uint256 _count) public onlyOwner {
        require(totalSupply() + _count <= 11, "W3F: Max 11 rainbow passes.");
        for (uint256 i = 1; i <= _count; i++) {
            _mint(msg.sender, i);
        }
        availablePassesCount -= _count;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function mint(uint256 _count, address _referrer) public payable {
        require(_count > 0, "W3F: Invalid number of NFTs to mint.");
        require(_referrer != msg.sender, "W3F: Invalid referrer.");
        require(totalSupply() < MAX_SUPPLY, "W3F: All NFTs have been minted.");
        require(!paused, "W3F: Minting paused.");
        uint256 supply = totalSupply();
        require(supply + _count <= MAX_SUPPLY, "W3F: Number exceeds maximum supply.");
        uint256 cost = _getCost(_count, _referrer);
        require(msg.value >= cost, "W3F: Insufficient payment.");
        require(_count <= MAX_MINT_COUNT - mintedCount[msg.sender], "W3F: Mint limit reached.");
        mintedCount[msg.sender] += _count;
        _mintRandom(msg.sender, _count);

        address commissionRecipient = _referrer;
        if (commissionRecipient != address(0)) {
            emit Referral(_referrer, msg.sender);
        }

        if (commissionBasePoints > 0) {
            if (commissionRecipient == address(0)) {
                commissionRecipient = owner();
            }
            uint256 commissionAmount = cost * commissionBasePoints / 10000;
            (bool sent, ) = commissionRecipient.call{value: commissionAmount}("");
            require(sent, "W3F: Refferer failed to receive.");
            emit Commission(_referrer, msg.sender, commissionAmount, _count);
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721, IERC721Metadata) returns (string memory) {
        require(_exists(tokenId), "W3F: URI query for nonexistent token.");

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();

        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
            : "";
    }

    function walletOf(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIds;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public onlyOwner {
        (bool sent, ) = payable(owner()).call{value: address(this).balance}("");
        require(sent);
    }

    function withdrawToken(address _token) public onlyOwner {
        ERC20 token = ERC20(_token);
        uint256 tokenBalance = token.balanceOf(address(this));
        token.transfer(owner(), tokenBalance);
    }

    function _mintRandom(address to, uint _count) internal virtual {
        require(_msgSender() == tx.origin, "ERC721r: Contracts cannot mint.");

        uint newAvailablePassesCount = availablePassesCount;
        for (uint256 i; i < _count; ++i) { // Do this ++ unchecked?
            uint256 tokenId = getRandomAvailableTokenId(to, newAvailablePassesCount);
            _mint(to, tokenId);
            --newAvailablePassesCount;
        }

        availablePassesCount = newAvailablePassesCount;
    }

    function getRandomAvailableTokenId(address to, uint newAvailablePassesCount)
        internal
        returns (uint256)
    {
        uint256 randomNum = uint256(
            keccak256(
                abi.encode(
                    to,
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    block.difficulty,
                    blockhash(block.number - 1),
                    address(this),
                    newAvailablePassesCount
                )
            )
        );
        uint256 randomIndex = randomNum % newAvailablePassesCount;
        return getAvailableTokenAtIndex(randomIndex, newAvailablePassesCount);
    }

    // Implementation of the Fisher-Yates shuffle (https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle)
    function getAvailableTokenAtIndex(uint256 index, uint newAvailablePassesCount)
        internal
        returns (uint256)
    {
        uint256 result;
        if (availablePasses[index] == 0) {
            // Index is still an available token.
            result = index;
        } else {
            // Index itself is not available, but the value at that index is.
            result = availablePasses[index];
        }

        uint256 lastIndex = newAvailablePassesCount - 1;
        if (index != lastIndex) {
            // Replace the value at index with the data from the last index in the array,
            // since we are going to decrease the array size afterwards.
            uint256 lastValInArray = availablePasses[lastIndex];
            if (lastValInArray == 0) {
                // This means the index itself is still an available token
                availablePasses[index] = lastIndex;
            } else {
                // Index itself is not an available token, but the value at that index is.
                availablePasses[index] = lastValInArray;
                delete availablePasses[lastIndex];
            }
        }

        return result;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _getCost(uint256 _count, address _referrer) private view returns (uint256) {
        return price * _count;
    }

    receive() external payable {}
}