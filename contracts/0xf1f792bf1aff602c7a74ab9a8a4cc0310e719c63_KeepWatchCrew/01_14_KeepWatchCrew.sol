// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract KeepWatchCrew is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    enum SaleModes { NONE, VIP_PRESALE, PUBLIC_SALE }

    string public notRevealedUri;
    string private baseTokenURI;
    SaleModes public saleMode = SaleModes.NONE;

    mapping(address => bool) public presaleAddresses;
    mapping(address => bool) public vipAddresses;
    mapping(address => uint256) mintedAmounts;

    bool public revealed = false;
    bool public paused = false;

    uint256 public constant MAX_ELEMENTS = 6969;
    uint256 public PRICE = 69 * (10**15);   // 0.069 ETH
    uint256 public DISCOUNT_PRICE = 59 * (10**15);  // 0.059 ETH
    uint256 public maxVIPMint = 1;
    uint256 public maxPresaleMint = 4;
    uint256 public maxPublicMint = 8;
    uint256 public publicSaleDate = 1639695600;

    address payable public constant payoutAddress =
        payable(0x032b023b216Dc3b9A30975ABf1f51De92a764a46);

    event CreateKWC(uint256 indexed id);

    constructor(string memory baseURI, string memory _notRevealedUri) 
        ERC721("KeepWatchCrew", "KWC")
    {
        setBaseURI(baseURI);
        // Dummy IPFS metadata JSON URI for before reveal
        setNotRevealedURI(_notRevealedUri);
        // Pause minting by default
        pause(true);
    }

    function isVIP(address _user) public view returns (bool) {
        return vipAddresses[_user];
    }

    function isInPresale(address _user) public view returns (bool) {
        return presaleAddresses[_user];
    }

    function totalMint(address _user) public view returns (uint256) {
        return mintedAmounts[_user];
    }

    function _mintAnElement(address _to) internal {
        uint256 id = totalSupply() + 1;
        _safeMint(_to, id);
        emit CreateKWC(id);
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

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseTokenURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    function mint(uint256 _count) public payable {
        require(!paused, "Pausable: paused");
        uint256 total = totalSupply();
        address sender = _msgSender();
        require(_count > 0);

        require(total <= MAX_ELEMENTS, "Sale end");
        require(total + _count <= MAX_ELEMENTS, "Max limit");

        // Nobody can mint except the contract owner if it's in default mode
        if (saleMode == SaleModes.NONE) {
            require(sender == owner());
        }

        uint256 mintedAmount = mintedAmounts[sender];
        bool isInPresaleList = isInPresale(sender);
        bool isInVIP = isVIP(sender);

        if (saleMode == SaleModes.VIP_PRESALE) {
            if (sender != owner()) {
                require(isInVIP || isInPresaleList);

                if (isInVIP) {
                    if (mintedAmount == 0) {
                        require(_count == maxVIPMint, "You can't mint more than allowed number of tokens");
                    } else {
                        require(isInPresaleList, "You are not allowed to mint");
                        uint256 maxMint = maxVIPMint + maxPresaleMint;
                        require(_count + mintedAmount <= maxMint, "You can't mint more than allowed number of tokens");
                        require(msg.value >= DISCOUNT_PRICE.mul(_count), "Value below price");
                    }
                } else {
                    require(_count + mintedAmount <= maxPresaleMint, "You can't mint more than allowed number of tokens");
                    require(msg.value >= DISCOUNT_PRICE.mul(_count), "Value below price");
                }
            }
        }

        if (saleMode == SaleModes.PUBLIC_SALE) {
            if (sender != owner()) {
                require(_count <= maxPublicMint, "Number of mintable tokens limited per wallet");
                require(msg.value >= PRICE.mul(_count), "Value below price");
            }
        }

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(sender);
            mintedAmounts[sender] += 1;
        }
    }

    // Only owner

    // Change Mode
    function activateNextSaleMode() external onlyOwner {
        if (saleMode == SaleModes.NONE) {
            saleMode = SaleModes.VIP_PRESALE;
        } else if (saleMode == SaleModes.VIP_PRESALE) {
            saleMode = SaleModes.PUBLIC_SALE;
        }
    }

    // Add users to Presale list
    function addUsersToPresaleList(address[] calldata _users) external onlyOwner {
        for(uint256 i = 0; i < _users.length; i++) {
            address user = _users[i];
            require(user != address(0), "Null Address");

            presaleAddresses[user] = true;
        }
    }

    function removeUsersFromPresaleList(address[] calldata _users) external onlyOwner {
        for(uint256 i = 0; i < _users.length; i++) {
            address user = _users[i];
            require(user != address(0), "Null Address");

            presaleAddresses[user] = false;
        }
    }

    // Add users to VIP list
    function addUsersToVIPList(address[] calldata _users) external onlyOwner {
        for(uint256 i = 0; i < _users.length; i++) {
            address user = _users[i];
            require(user != address(0), "Null Address");

            vipAddresses[user] = true;
        }
    }

    function removeUsersFromVIPList(address[] calldata _users) external onlyOwner {
        for(uint256 i = 0; i < _users.length; i++) {
            address user = _users[i];
            require(user != address(0), "Null Address");

            vipAddresses[user] = false;
        }
    }

    // Reveals real metadata for NFTs
    function reveal() public onlyOwner {
        revealed = true;
    }

    // Pause/unpause contract
    function pause(bool val) public onlyOwner {
        paused = val;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setNotRevealedURI(string memory _notRevealedUri) public onlyOwner {
        notRevealedUri = _notRevealedUri;
    }

    function updateMaxPresaleAmount(uint256 _amount) external onlyOwner {
        maxPresaleMint = _amount;
    }

    function updateMaxPublicAmount(uint256 _amount) external onlyOwner {
        maxPublicMint = _amount;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        payoutAddress.transfer(balance);
    }
}