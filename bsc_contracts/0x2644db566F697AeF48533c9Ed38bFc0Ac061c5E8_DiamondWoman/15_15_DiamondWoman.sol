pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DiamondWoman is ERC721Enumerable, Ownable {
    using Strings for uint256;
    string public baseURI;
    string public baseExtension = ".json";
    string public notRevealedUri;
    address[] public whitelistedAddresses;
    bool public revealedActive = false;
    bool public pauseMode = false;
    bool public preSalesMode = true;
    uint256 public cost = 1 * 10**18;
    uint256 public costPS = 1 * 10**18;
    uint256 public maxCollection = 9999;

    IERC20 public tokenAddress;

    constructor() ERC721("BNB Diamond Woman ", "BNBWMN") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function isWhitelisted(address _user) public view returns (bool) {
        for (uint256 i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function setBUSDAddress(address _tokenAddress) public onlyOwner {
        tokenAddress = IERC20(_tokenAddress);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (revealedActive == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function mint(uint256 _mintAmount) public {
        require(!pauseMode, "Pause Mode ON");
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "Select 1 NFT");
        require(supply + _mintAmount <= maxCollection, "Collecton Sold");

        if (msg.sender != owner()) {
            if (preSalesMode == true) {
                uint256 valuePS = _mintAmount * costPS;
                require(
                    tokenAddress.balanceOf(msg.sender) >= valuePS,
                    "Insufficient BUSD balance"
                );
                require(!isWhitelisted(msg.sender), "Wallet Whitelisted");
                tokenAddress.transferFrom(msg.sender, address(this), valuePS);
            } else {
                uint256 valueCost = _mintAmount * cost;
                require(
                    tokenAddress.balanceOf(msg.sender) >= valueCost,
                    "Insufficient BUSD balance"
                );
                tokenAddress.transferFrom(msg.sender, address(this), valueCost);
            }
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function Airdrop(address _to, uint256 _mintAmount) external onlyOwner {
        uint256 supply = totalSupply();
        require(
            supply + _mintAmount <= maxCollection,
            "Cant airdrop more NFTs"
        );
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, supply + i);
        }
    }

    function turnRevealMode() public onlyOwner {
        revealedActive = true;
    }

    function whitelistUsers(address[] calldata _users) public onlyOwner {
        whitelistedAddresses = _users;
    }

    function setpauseMode(bool _state) public onlyOwner {
        pauseMode = _state;
    }

    function setpreSalesMode(bool _state) public onlyOwner {
        preSalesMode = _state;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setCostePS(uint256 _newCostPS) public onlyOwner {
        costPS = _newCostPS;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function withdraw() public onlyOwner {
        // Transfer BUSD balance to contract owner
        require(
            tokenAddress.transfer(
                owner(),
                tokenAddress.balanceOf(address(this))
            ),
            "BUSD withdrawal failed"
        );
    }
}