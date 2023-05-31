// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NextTrialRunPoster is ERC1155, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 2692;
    uint256 public constant MAX_POSTERS_TYPE = 20;
    
    uint256 public currentId;
    uint256 public totalSupply;
    address public nextTrialRunPosterMinter;

    string private name_;
    string private symbol_;   

    event SetNextTrialRunPosterMinter(address nextTrialRunPosterMinter);
    event SetURI(string uri);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC1155(_uri)  {
        name_ = _name;
        symbol_ = _symbol;
    }

    //modifier to check owner or store condition
    modifier onlyOwnerOrStore() 
    {
        require(
            nextTrialRunPosterMinter == msg.sender || owner() == msg.sender,
            "caller must be NextTrialRunPosterMinter or owner"
        );
        _;
    }

    function setNextTrialRunPosterMinter(address _nextTrialRunPosterMinter) 
        external 
        onlyOwner 
    {
        nextTrialRunPosterMinter = _nextTrialRunPosterMinter;
        emit SetNextTrialRunPosterMinter(_nextTrialRunPosterMinter);
    }    

    function name() public view returns (string memory) {
        return name_;
    }

    function symbol() public view returns (string memory) {
        return symbol_;
    } 

    function mint(address _to, uint256 numMints) 
        public 
        onlyOwnerOrStore 
    {
        require((totalSupply + numMints) <= MAX_SUPPLY, "Max supply reached");
        require(numMints >= 1, "Number of mints must be at least 1");

        if (numMints > 1) {
            uint256 maxTypes = numMints;
            if (maxTypes > MAX_POSTERS_TYPE) {
                maxTypes = MAX_POSTERS_TYPE;
            }
            uint256[] memory mintIds = new uint256[](maxTypes);
            uint256[] memory amounts = new uint256[](maxTypes);
            
            for (uint i=0; i<numMints; i++) {
                mintIds[i % MAX_POSTERS_TYPE] = currentId;
                amounts[i % MAX_POSTERS_TYPE] ++; 
                
                currentId ++;
                if (currentId >= MAX_POSTERS_TYPE) {
                    currentId = 0;
                }
            }
            _mintBatch(_to, mintIds, amounts, "");
        } else {
            _mint(_to, currentId, 1, "");

            currentId++;
            if (currentId >= MAX_POSTERS_TYPE) {
                currentId = 0;
            }
        }

        totalSupply += numMints;
    }

    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
        emit SetURI(newuri);
    }  

    function uri(uint256 _id) public view override returns (string memory) {
        require(_id < MAX_POSTERS_TYPE, "URI: nonexistent token");

        return string(abi.encodePacked(super.uri(_id), Strings.toString(_id)));
    }
}