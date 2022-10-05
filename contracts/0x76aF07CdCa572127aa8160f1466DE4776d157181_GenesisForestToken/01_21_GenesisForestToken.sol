//
//
//
///////////////////////////////////////////////////////////////////////////////////////////
//                                                  (                                    //
//  (                                               )\ )                              )  //
//  )\ )       (              (         (          (()/(         (       (         ( /(  //
// (()/(      ))\    (       ))\   (    )\   (      /(_))   (    )(     ))\   (    )\()) //
//  /(_))_   /((_)   )\ )   /((_)  )\  ((_)  )\    (_))_|   )\  (()\   /((_)  )\  (_))/  //
// (_)) __| (_))    _(_/(  (_))   ((_)  (_) ((_)   | |_    ((_)  ((_) (_))   ((_) | |_   //
//   | (_ | / -_)  | ' \)) / -_)  (_-<  | | (_-<   | __|  / _ \ | '_| / -_)  (_-< |  _|  //
//    \___| \___|  |_||_|  \___|  /__/  |_| /__/   |_|    \___/ |_|   \___|  /__/  \__|  //
//                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////
//
//
//

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract GenesisForestToken is ERC1155Burnable, Ownable {
    string public name = "GenesisForestToken";
    string public symbol = "GFT";

    string public contractUri = "https://nft.garten-staudinger.de/contract";

    uint256 public maxSupply;
    uint256 public price;

    uint256 public mintLimit = 2;
    mapping(address => uint256) private _mintCount;

    bool public isPublic = false;
    mapping(address => bool) private _whitelist;

    using Counters for Counters.Counter;
    Counters.Counter private _idTracker;

    constructor() ERC1155("https://nft.garten-staudinger.de/{id}") {
        _idTracker.increment();
    }

    function setUri(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function setContractURI(string memory newuri) public onlyOwner {
        contractUri = newuri;
    }

    function setMintLimit(uint256 _mintLimit) public onlyOwner {
        mintLimit = _mintLimit;
    }

    function getMintLimitByAddress(address _address)
        public
        view
        returns (uint256)
    {
        return mintLimit - _mintCount[_address];
    }

    function setIsPublic(bool _isPublic) public onlyOwner {
        isPublic = _isPublic;
    }

    function setWhitelist(address[] memory _addresses, bool _isWhitelisted)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _whitelist[_addresses[i]] = _isWhitelisted;
        }
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return _whitelist[_address];
    }

    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    function getAvailableSupply() public view returns (uint256) {
        return 1 + maxSupply - _idTracker.current();
    }

    function getPrice() public view returns (uint256) {
        return price;
    }

    function setTokenPriceAndSupply(uint256 _price, uint256 _maxSupply)
        public
        onlyOwner
    {
        price = _price;
        maxSupply = _maxSupply;
    }

    function airdrop(
        address[] memory to,
        uint256[] memory id,
        uint256[] memory amount
    ) public onlyOwner {
        require(
            to.length == id.length && to.length == amount.length,
            "Length mismatch"
        );
        for (uint256 i = 0; i < to.length; i++)
            _mint(to[i], id[i], amount[i], "");
    }

    function mint() public payable {
        require(price > 0, "Minting not available");
        require(_idTracker.current() <= maxSupply, "Not enough supply");
        require(msg.value >= price, "Not enough eth");
        require(_mintCount[msg.sender] < mintLimit, "Mint limit reached");

        if (!isPublic) {
            require(_whitelist[msg.sender] == true, "Not whitelisted");
        }

        _mint(msg.sender, _idTracker.current(), 1, "");
        _mintCount[msg.sender] += 1;
        _idTracker.increment();
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}