//
//
//
///////////////////////////////////////////////////
//   __  __ _ _         _  _                     //
//  |  \/  (_) |_____  | || |__ _ __ _ ___ _ _   //
//  | |\/| | | / / -_) | __ / _` / _` / -_) '_|  //
//  |_|  |_|_|_\_\___| |_||_\__,_\__, \___|_|    //
//                               |___/           //
///////////////////////////////////////////////////
//
//
//

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract TheFreeMintPass is ERC1155Burnable, Ownable, DefaultOperatorFilterer {
    string public name = "The Free Mint Pass";
    string public symbol = "TFMP";

    string public contractUri = "https://metadata.mikehager.de/mintpassContract.json";

    bool public isMintEnabled = true;

    uint256 public mintLimit = 1;
    mapping(address => uint256) private _mintCount;

    mapping(address => bool) private _whitelist;

    using Counters for Counters.Counter;
    Counters.Counter private _idTracker;

    constructor() ERC1155("https://metadata.mikehager.de/mintpass.json") {
        _idTracker.increment();
    }

    function setUri(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function setContractURI(string memory newuri) public onlyOwner {
        contractUri = newuri;
    }

    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    function setIsMintEnabled(bool isEnabled) public onlyOwner {
        isMintEnabled = isEnabled;
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

    function mint() public {
        require(isMintEnabled, "Mint not enabled");
        require(_mintCount[msg.sender] < mintLimit, "Mint limit reached");
        require(_whitelist[msg.sender] == true, "Not whitelisted");

        _mint(msg.sender, _idTracker.current(), 1, "");
        _mintCount[msg.sender] += 1;
        _idTracker.increment();
    }    
    
    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

     function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}