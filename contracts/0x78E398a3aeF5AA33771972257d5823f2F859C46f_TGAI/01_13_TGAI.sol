//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";

contract TGAI is ERC721A, Ownable {
    using Strings for uint256;

    address private _revenueRecipient;
    address public manager;

    string private _baseUri;
    
    uint public airdropped = 0;
    bool public saleActive = false;

    uint public constant COLLECTION_SIZE = 1111;
    uint public constant AIRDROP_LIMIT = 10;
    uint public price;
    
    constructor(
        address owner,
        address manager_,
        address revenueRecipient_,
        uint _price,
        string memory baseUri_
    )
        ERC721A("TGAI", "TGAI")
    {
        _revenueRecipient = revenueRecipient_;
        manager = manager_;
        price = _price;
        _baseUri = baseUri_;
        _safeMint(manager_, 1);
        _transferOwnership(owner);
    }

    modifier onlyManagers(){
        require(msg.sender == manager || msg.sender == owner(), "NOT_MANAGER");
        _;
    }

    function clearManager() external onlyManagers {
        manager = address(0);
    }

    function setRevenueRecipient(address revenueRecipient) external onlyManagers {
        _revenueRecipient = revenueRecipient;
    }

    function setSalePrice(uint _price) external onlyManagers {
        price = _price;
    }

    /// @notice collection owner has the option to airdrop a number of tokens up to defined limit
    function airdrop(address to, uint quantity) external onlyManagers {
        require(totalSupply() + quantity <= COLLECTION_SIZE, "EXCEEDS_COLLECTION_SIZE");
        require(airdropped + quantity <= AIRDROP_LIMIT, "EXCEEDS_AIRDROP_LIMIT");
        airdropped = airdropped + quantity;
        _safeMint(to, quantity);
    }

    function setSaleActive(bool _active) external onlyManagers {
        if(_exists(0)){
            _burn(0); // burn the opensea setup token
        }
        saleActive = _active;
    }

    function setBaseURI(string memory baseUri) external onlyManagers {
        _baseUri = baseUri;
    }

    /// @dev override base uri. It will be combined with token ID
    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    /// @notice Withdraw's contract's balance to the withdrawal address
    function withdraw() public {
        uint256 balance = address(this).balance;
        require(balance > 0, "NO_BALANCE");

        (bool success, ) = payable(_revenueRecipient).call{ value: balance }("");
        require(success, "WITHDRAW_FAILED");
    }

    function mint(uint quantity) external payable {
        mintTo(msg.sender, quantity);
    }

    function mintTo(address _address, uint quantity) public payable {
        require(quantity > 0, "INVALID_QUANTITY");
        require(saleActive, "PUBLIC_SALE_INACTIVE");
        require(totalSupply() + quantity <= COLLECTION_SIZE, "EXCEEDS_COLLECTION_SIZE");

        uint cost;
        cost = price * quantity;
        require(msg.value >= cost, "VALUE_TOO_LOW");

        if(msg.value > cost){
            (bool success, ) = payable(msg.sender).call{ value: msg.value - cost }("");
            require(success, "REFUND_SURPLUS_FAILED");
        }

        withdraw();
        _safeMint(_address, quantity);
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_exists(id), "INVALID_ID");

        return string(abi.encodePacked(_baseURI(), id.toString(), ".json"));
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}