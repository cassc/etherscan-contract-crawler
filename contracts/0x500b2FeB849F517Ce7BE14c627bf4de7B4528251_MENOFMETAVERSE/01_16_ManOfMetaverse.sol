// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract MENOFMETAVERSE is ERC721Enumerable, Ownable {
    using Strings for uint256;
    uint256 public balance;
    string public baseURI;
    string public currentPhase;
    string public baseExtension = ".json";
    string public notRevealedUri;
    uint256 public cost;
    uint256 public maxSupply;
    uint256 public nftPerAddressLimit;
    bool public paused = false;
    bool public revealed = false;
    bool public onlyWhitelisted = false;
    uint256 public reservedNft = 300;
    address public reservedAddress = 0xFf225940bE64909512F8A37A4ef161595F0f294a;
    address[] private whitelistedAddresses;
    mapping(address => uint256) public addressMintedBalance;
    mapping(string => uint256) private currentPhaseSupply;
    mapping(address => uint256) private phaseMintBalance;
    address [] investers;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
        setPhase("VVIP");
        mint(10);
    }
    function resetPhaseMintBalance() private {
        for (uint i=0; i< investers.length ; i++) {
            phaseMintBalance[investers[i]] = 0;
        }
    }
    function investersArrayPush(address _address) private {
        bool isExist = false;
        for (uint i=0; i< investers.length ; i++) {
            if(investers[i] == _address) {
                isExist = true;
                break;
            }
        }
        if(!isExist) investers.push(msg.sender);
    }
    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(uint256 _mintQuantity) public payable {
        require(!paused, "the contract is paused");
        uint256 supply = totalSupply();
        require(_mintQuantity > 0, "need to mint at least 1 NFT");
        uint256 userMintedCount = phaseMintBalance[msg.sender];
        if (msg.sender == reservedAddress) {
            require(
                supply + _mintQuantity <= maxSupply,
                "max NFT limit exceeded"
            );
            require(
                keccak256(abi.encodePacked("PUBLIC")) ==
                    keccak256(abi.encodePacked(currentPhase)),
                "wait for public phase"
            );
            require(
                userMintedCount + _mintQuantity <= reservedNft,
                "reserved NFT limit exceeded"
            );
            require(msg.value >= cost * _mintQuantity, "insufficient funds");
        } else {
            if (msg.sender != owner()) {
                keccak256(abi.encodePacked("PUBLIC")) ==
                    keccak256(abi.encodePacked(currentPhase))
                    ? require(
                        supply + _mintQuantity <= maxSupply - reservedNft,
                        "max NFT limit exceeded"
                    )
                    : require(
                        supply + _mintQuantity <= maxSupply,
                        "max NFT limit exceeded"
                    );

                if (onlyWhitelisted == true) {
                    require(
                        isWhitelisted(msg.sender),
                        "user is not whitelisted"
                    );
                }
                require(
                    userMintedCount + _mintQuantity <= nftPerAddressLimit,
                    "max NFT per address exceeded"
                );
                require(
                    msg.value >= cost * _mintQuantity,
                    "insufficient funds"
                );
            }
        }
        investersArrayPush(msg.sender);
        for (uint256 i = 1; i <= _mintQuantity; i++) {
            addressMintedBalance[msg.sender]++;
            phaseMintBalance[msg.sender]++;
            currentPhaseSupply[currentPhase]++;
            _safeMint(msg.sender, supply + i);
        }
        withdraw();
    }
    
    function isWhitelisted(address _user) public view returns (bool) {
        for (uint256 i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
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
    function getCurrentPhaseSupply() public view returns (uint256) {
        return currentPhaseSupply[currentPhase];
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
        string memory currentBaseURI = revealed == false ? notRevealedUri : _baseURI();
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

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
        nftPerAddressLimit = _limit;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setMaxSupply(uint256 _newSupply) public onlyOwner {
        maxSupply = _newSupply;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }

    function whitelistUsers(address[] calldata _users) public onlyOwner {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
    }

    function getAllWhitelistUsers()
        public
        view
        onlyOwner
        returns (address[] memory)
    {
        return whitelistedAddresses;
    }

    function withdraw() public payable {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function setPhase(string memory _phase) public onlyOwner {
        if (
            keccak256(abi.encodePacked("VVIP")) ==
            keccak256(abi.encodePacked(_phase))
        ) {
            currentPhase = _phase;
            setCost(140000000000000000);
            setNftPerAddressLimit(4);
            setMaxSupply(500);
            resetPhaseMintBalance();
        } else if (
            keccak256(abi.encodePacked("WHITELIST")) ==
            keccak256(abi.encodePacked(_phase))
        ) {
            currentPhase = _phase;
            setCost(180000000000000000);
            setNftPerAddressLimit(4);
            setOnlyWhitelisted(true);
            setMaxSupply(2500);
            resetPhaseMintBalance();
        } else if (
            keccak256(abi.encodePacked("PRIVATE")) ==
            keccak256(abi.encodePacked(_phase))
        ) {
            currentPhase = _phase;
            setCost(220000000000000000);
            setNftPerAddressLimit(6);
            setOnlyWhitelisted(false);
            setMaxSupply(5000);
            resetPhaseMintBalance();
        } else if (
            keccak256(abi.encodePacked("PUBLIC")) ==
            keccak256(abi.encodePacked(_phase))
        ) {
            currentPhase = _phase;
            setCost(250000000000000000);
            setNftPerAddressLimit(8);
            setMaxSupply(10000);
            resetPhaseMintBalance();
        } else require(false, "incorrect input phase");
    }
}