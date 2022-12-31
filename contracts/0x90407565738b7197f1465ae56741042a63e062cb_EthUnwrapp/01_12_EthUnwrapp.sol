// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

interface IValidator {
    function validate(address _addr) external view returns (bool);
}

/**

    ______________  ____  ___   ___       ______  ___    ____  ____ 
   / ____/_  __/ / / / / / / | / / |     / / __ \/   |  / __ \/ __ \
  / __/   / / / /_/ / / / /  |/ /| | /| / / /_/ / /| | / /_/ / /_/ /
 / /___  / / / __  / /_/ / /|  / | |/ |/ / _, _/ ___ |/ ____/ ____/ 
/_____/ /_/ /_/ /_/\____/_/ |_/  |__/|__/_/ |_/_/  |_/_/   /_/      


website: ethunwr.app
A project by harrydenley.com
*/

contract EthUnwrapp is ERC1155, ERC1155Holder {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    event EditionCreated(uint256 indexed editionId);
    event Minted(address indexed _from, uint256 indexed editionId, uint _value);

    address public owner;
    address public beneficiary;

    // Edition data
    struct Edition {
        uint256 editionId;
        string editionName;
        string uri;
        uint16 mintLimit;  
        uint256 minMintCost;     
        uint32 openTimestamp;
        uint32 closeTimestamp;
        address validator;
    }  
    Edition[] editions;

    // Tracks how many have been sent to users from this contract
    mapping(uint256 => uint16) public mintTracking;

    constructor() ERC1155("") {
        owner = msg.sender;
        beneficiary = msg.sender;
    }

    function name() external pure returns (string memory _name) {
        return "ethunwr.app";
    }

    function symbol() external pure returns (string memory _symbol) {
        return "ETHUNWRAPP";
    }

    // Mint for yourself
    function mint(uint256 _editionId) public payable {
        _doMint(_editionId, msg.sender);
    }

    // Mint for friend
    function mintForFren(uint256 _editionId, address _addr) public payable {
        _doMint(_editionId, _addr);
    }

    // Returns the edition struct - data about the edition
    function getEdition(uint256 _editionId) public view returns(Edition memory) {
        return editions[_editionId];
    }

    // Returns edition mint count (bought from mint())
    function getEditionMintCount(uint256 _editionId) public view returns(uint16 array) {
        return mintTracking[_editionId];
    }

    function uri(uint256 _editionId) public view override(ERC1155) returns (string memory) {
        return editions[_editionId].uri;
    }

    function _doMint(uint256 _editionId, address _mintForAddress) internal {
        // Check to see if the mint is open
        require(
            editions[_editionId].openTimestamp < block.timestamp,
            "Edition is not yet opened to minting"
        );

        // Check to see if the edition is not closed
        require(
            editions[_editionId].closeTimestamp > block.timestamp,
            "Edition is closed to minting"
        );

        // Check to see if they have supplied the min mint cost (anything over is considered a donation)
        require(
            editions[_editionId].minMintCost <= msg.value,
            "Minimum mint cost is more than sent"
        );

        // Check to see if they hold this edition already
        require(
            balanceOf(_mintForAddress, _editionId) == 0,
            "You already own this edition"
        );

        // See if we have minted out
        require(
            mintTracking[_editionId] < editions[_editionId].mintLimit,
            "Edition has reached mint limit"
        );

        // See if there is extra validation rules before mint
        if(editions[_editionId].validator != address(0)) {
            (bool isValid) = IValidator(editions[_editionId].validator).validate(_mintForAddress);
            require(isValid, "Mint validation rule failed");
        }

        // Update the mint value
        mintTracking[_editionId] = mintTracking[_editionId] + 1;

        // Mint the NFT
        emit Minted(_mintForAddress, _editionId, msg.value);
        _mint(_mintForAddress, _editionId, 1, "");
    }

    function isMintingOpen(uint8 _editionId) public view returns (bool isOpen) {
        return
            editions[_editionId].openTimestamp <= block.timestamp &&
            editions[_editionId].closeTimestamp > block.timestamp;
    }

    function setURI(string memory _uri) public {
        require(owner == msg.sender, "Not authorised!");
        _setURI(_uri);
    }

    function changeOwner(address _addr) public {
        require(owner == msg.sender, "Not authorised!");
        owner = _addr;
    }

    function changeBeneficiary(address _addr) public {
        require(owner == msg.sender, "Not authorised!");
        beneficiary = _addr;
    }

    function withdraw() public {
        payable(beneficiary).transfer(address(this).balance);
    }

    function createEdition(
        string calldata _editionName,
        string calldata _uri,
        uint32 _openTimestamp,
        uint32 _closeTimestamp,
        uint16 _maxMintLimit,
        uint256 _minMintCostInWei,
        address _validator
    ) public returns (uint256) {
        require(owner == msg.sender, "Not authorised!");

        uint256 editionId = _tokenIds.current();

        Edition memory edition = Edition(
            editionId,
            _editionName,
            _uri,
            _maxMintLimit,
            _minMintCostInWei,
            _openTimestamp,
            _closeTimestamp,
            _validator
        );

        editions.push(edition);

        _tokenIds.increment();

        emit EditionCreated(editionId);

        return editionId;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC1155Receiver) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}