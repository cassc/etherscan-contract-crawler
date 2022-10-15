/*
▒█▀▀▀ █░█ ░▀░ ▀▀█▀▀ 　 ▀▀█▀▀ █░░█ █▀▀ 　 ▒█░░▒█ █▀▀ █▀▀▄
▒█▀▀▀ ▄▀▄ ▀█▀ ░░█░░ 　 ░░█░░ █▀▀█ █▀▀ 　 ▒█▒█▒█ █▀▀ █▀▀▄
▒█▄▄▄ ▀░▀ ▀▀▀ ░░▀░░ 　 ░░▀░░ ▀░░▀ ▀▀▀ 　 ▒█▄▀▄█ ▀▀▀ ▀▀▀░
  ___     _                   _         _   _      _ _
 | _ \___| |_ _  _ _ _ _ _   | |_ ___  | | | |_ _ (_) |_ _  _
 |   / -_)  _| || | '_| ' \  |  _/ _ \ | |_| | ' \| |  _| || |
 |_|_\___|\__|\_,_|_| |_||_|  \__\___/  \___/|_||_|_|\__|\_, |
                                                         |__/

Come Join us in our unique Rave!
www.exitheweb.party
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A/ERC721A.sol";
import "./utils/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MOTS is ERC721A, Ownable, ReentrancyGuard {
    string public _tokenURI = "https://gateway.pinata.cloud/ipfs/QmTah62S3ENXuq92wcv1KVJE8oYtHSgH1HiSFiKELDGzir";
    string public _raveTokenURI = "https://gateway.pinata.cloud/ipfs/QmTah62S3ENXuq92wcv1KVJE8oYtHSgH1HiSFiKELDGzir";
    uint256 public maxSupply = 300;
    bool public saleIsActive = true;

    uint256 public FREN_PRICE = 0.0222 ether;
    uint256 public RAVE_PRICE = 0.0555 ether;

    // codes list
    mapping(bytes32 => bool) private codes;
    // codes to enter event
    bytes32 private entercode;
    // mapping of address to amount
    mapping(address => bool) public purchased;
    // used codes list
    mapping(bytes32 => bool) private usedCodes;
    // guests that marked their physical presence at the event
    mapping(uint256 => bool) public present;

    constructor() ERC721A("Exit the Web", "MOTS") {}

    /** ADMIN */
    /// @dev reduce total supply
    /// @param newMaxSupply new total supply must be inferior to previous
    function reduceTotalSupply(uint256 newMaxSupply) public onlyOwner {
        require(newMaxSupply < maxSupply, "Can only reduce supply");
        maxSupply = newMaxSupply;
    }

    /// @dev change the base uri
    /// @param uri base uri
    function setTokenURI(string memory uri, string memory raveuri) public onlyOwner {
        _tokenURI = uri;
        _raveTokenURI = raveuri;
    }

    /// @dev add codes
    /// @param _codes string[]
    function addCodes(bytes32[] memory _codes) public onlyOwner {
        for (uint256 i = 0; i < _codes.length; i++) {
            codes[_codes[i]] = true;
        }
    }

    /// @dev add enter code
    /// @param _code string
    function addEnterCodes(bytes32 _code) public onlyOwner {
        entercode = _code;
    }

    /// @dev Pause sale if active, make active if paused
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (present[tokenId]) return _raveTokenURI;
        else return _tokenURI;
    }

    /// @dev mint number of nfts
    /// @param user the user to mint
    function mint(address user) public payable nonReentrant returns (uint256) {
        require(saleIsActive, "Sale must be active to mint");
        require(totalSupply() < maxSupply, "Purchase exceeds max supply");
        require(msg.value >= RAVE_PRICE, "pls attach 0.0555 ether per ticket fren");

        purchased[user] = true;

        _safeMint(user, 1);
        return totalSupply();
    }

    function teamMinting(address _address, uint256 _tickets) public onlyOwner {
        uint256 totaltickets = totalSupply();
        require(totaltickets + _tickets < maxSupply, "Purchase exceeds max supply");
        _safeMint(_address, _tickets);
    }

    /// @dev mint number of nfts
    /// @param _code the amount to mint
    function mint_promo(string memory _code) public payable nonReentrant returns (uint256) {
        bytes32 code = keccak256(abi.encodePacked(_code));
        require(saleIsActive, "Sale must be active to mint");
        require(codes[code] && !usedCodes[code], "Invalid code");
        require(!purchased[msg.sender], "User already purchased");
        require(totalSupply() < maxSupply, "Purchase exceeds max supply");
        require(msg.value >= FREN_PRICE, "pls attach 0.0222 ether per ticket fren");

        purchased[msg.sender] = true;
        usedCodes[code] = true;

        _safeMint(msg.sender, 1);
        return totalSupply();
    }

    /// @dev enter event
    /// @param _id the amount to mint
    function enterRave(uint256 _id, string memory _code) public nonReentrant {
        bytes32 code = keccak256(abi.encodePacked(_code));
        address raver = ownerOf(_id);
        require(code == entercode, "Invalid code");
        require(raver == msg.sender, "User is not the owner of that NFT");
        present[_id] = true;
    }

    function updatePrices(uint256 _frenPrice, uint256 _ravePrice) external onlyOwner {
        FREN_PRICE = _frenPrice;
        RAVE_PRICE = _ravePrice;
    }

    function raveFundus() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }
}