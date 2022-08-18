//SPDX-License-Identifier: MIT

pragma solidity >=0.8.1;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CurveClubOSAnnualMembership is ERC721URIStorage, Ownable, ReentrancyGuard {
    using Strings for uint256;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    bool public isSaleActive = false;
    bool public isRevealed = false;

    bool public onlyAllowListed = true;
    address[] public allowlistAddresses;

    uint256 public MAX_SUPPLY = 1000;
    uint256 public constant MAX_CURVE_MINT = 1;
    uint256 public price = 2 ether; 

    string public notRevealedUri;
    string private cid;

    mapping(address => bool) public hasMinted; // ensures user cannot purchase, transfer and then purchase another
    mapping(address => uint256) public dateMinted; // the time a user minted their NFT
    mapping(uint256 => uint256) public tokenMinted; // the time a token has been minted

    event CurveNFTMinted(address indexed sender, uint256 tokenId);
    event Attest(address indexed to, uint256 indexed tokenId);
    event Revoke(address indexed to, uint256 indexed tokenId);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _cid,
        string memory _initNotRevealedUri
    ) ERC721(_name, _symbol) {
        cid = _cid;
        _tokenIds.increment();
        setNotRevealedURI(_initNotRevealedUri);
    }

    function mint(uint256 _mintAmount) external payable {
        require(isSaleActive == true, "Hold up! The sale is not active yet");
        require(isAllowlisted(msg.sender), "User is not allowlisted");
        require(_mintAmount > 0, "You can't buy 0 memberships");
        
        require((_tokenIds.current() + _mintAmount) <= MAX_SUPPLY, "max NFT limit exceeded");        
        require(msg.value >= price * _mintAmount, "insufficient funds");
        
        if (msg.sender != owner()){
            require(hasMinted[msg.sender] != true, "Address has already minted");
            require( _mintAmount <= MAX_CURVE_MINT, "max mint amount exceeded");
        }

        hasMinted[msg.sender] = true; 
        dateMinted[msg.sender] = block.timestamp;
        uint256 newTokenId = _tokenIds.current();
        tokenMinted[newTokenId] = newTokenId;
        _tokenIds.increment();
        _safeMint(msg.sender, newTokenId);

        emit CurveNFTMinted(msg.sender, newTokenId);
    }

        function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _tokenId <= _tokenIds.current(),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (isRevealed == false) {
            return notRevealedUri;
        }

        string memory uriStart = "ipfs://";
        string memory uriEnd = ".json";

        return
            string(
                abi.encodePacked(
                    uriStart,
                    cid,
                    "/",
                    _tokenId.toString(),
                    uriEnd
                )
            );
    }


    function setActive(bool change) public onlyOwner {
        isSaleActive = change;
    }

    // set nft price
    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function setMaxSupply(uint256 _supply) external onlyOwner {
        MAX_SUPPLY = _supply;
    }


    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setRevealed(bool _state) public onlyOwner {
        isRevealed = _state;
    }

    function setCID(string memory newCID) public onlyOwner {
        cid = newCID;
    }

    function resetMembership(address newOwner, address oldOwner) public onlyOwner {
        dateMinted[newOwner] = dateMinted[oldOwner];
        dateMinted[oldOwner] = 0;
    }



    modifier hasExpired() {
        
        if (msg.sender != owner()){
            require(dateMinted[msg.sender] > 0, "Incorrect Wallet");
            require(
            (dateMinted[msg.sender] + (365 * 24 * 60 * 60)) > block.timestamp,
            "Your membership has expired"
            );
            _;
        }
        _;

        
    }

    function isMember() public view returns (bool) {
        if (dateMinted[msg.sender] > 0) {
            return true;
        } else {
            return false;
        }
    }

    function howLongMember(address tokenHolder) public view returns (uint256 timeMember) {
        if (msg.sender == tokenHolder || msg.sender == owner()){
            if (isMember()){
                timeMember = block.timestamp - dateMinted[tokenHolder];
                return timeMember;
            }
            else {
                return 0;
            }
        }
    }

    function timeTilExpire(address tokenHolder) public view hasExpired() returns (uint256 timeLeft) {
        if (msg.sender == tokenHolder || msg.sender == owner()){
            if (isMember()) {
                timeLeft = (dateMinted[tokenHolder] + (365 * 24 * 60 * 60)) -
                    block.timestamp;
                return timeLeft;
            }
            else {
                return 0;
            }
        }
    }

    function setonlyAllowListed(bool _state) public onlyOwner {
        onlyAllowListed = _state;
    }

    function allowlistUsers(address[] calldata _users) public onlyOwner {
        delete allowlistAddresses;
        allowlistAddresses = _users;
    }

    function isAllowlisted(address _user) public view returns (bool) {
        for (uint256 i = 0; i < allowlistAddresses.length; i++) {
            if (allowlistAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }


    function revokeMembership(uint256 tokenId) onlyOwner external {
        dateMinted[ownerOf(tokenId)] = 0;
        tokenMinted[tokenId] = 0;
        _burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override virtual {
        require((from == address(0) || from == address(owner()) || to == address(0) || to == owner()), "You cannot transfer this token");
    }


    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override virtual {
        if (from == address(0)){
            emit Attest(to, tokenId);
        } else if (to == address(0)){
            emit Revoke(to, tokenId);
        }
    }

    function withdraw() public payable onlyOwner nonReentrant {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }


}