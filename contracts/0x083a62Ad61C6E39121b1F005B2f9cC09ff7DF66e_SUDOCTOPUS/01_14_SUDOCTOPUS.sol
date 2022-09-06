// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

contract SUDOCTOPUS is Ownable, ERC721A, PaymentSplitter {
    using Strings for uint256;

    enum Step {
        Before,
        TeamMint
    }

    string public baseURI;

    Step public sellingStep;

    uint256 private constant MAX_SUPPLY = 888;
    // MAX NFT FOR PUBLIC

    uint256 private teamLength;

    constructor(
        address[] memory _team,
        uint256[] memory _teamShares,
        string memory _baseURI
    ) ERC721A("SUDOCTOPUS", "OCTO") PaymentSplitter(_team, _teamShares) {
        baseURI = _baseURI;
        teamLength = _team.length;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    

    function teamMint(uint256 _quantity)
        external
        onlyOwner
    {
        require(sellingStep == Step.TeamMint, "Public step is still active ");
        require(totalSupply() + _quantity <= MAX_SUPPLY,"Max supply exceeded");
        _safeMint(msg.sender, _quantity);
    }


    function setBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function currentTime() internal view returns (uint256) {
        return block.timestamp;
    }

    function setStep(uint256 _step) external onlyOwner {
        sellingStep = Step(_step);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "URI query for nonexistent token");

        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    //ReleaseALL
    function releaseAll() external {
        for (uint256 i = 0; i < teamLength; i++) {
            release(payable(payee(i)));
        }
    }

    receive() external payable override {
        revert("Only if you mint");
    }
}