// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MooseERC721.sol";

interface IYieldToken {
    function burn(address _from, uint256 _amount) external;
    function updateReward(address _from, address _to) external;
}

contract Moose is MooseERC721 {
    modifier mooseOwner(uint256 mooseId) {
        require(ownerOf(mooseId) == msg.sender, "Cannot interact with a Moose you do not own");
        _;
    }

    IYieldToken public yieldToken;
    
    uint256 constant public BREED_PRICE = 600 ether;
    
    event MooseBreeding(uint256 mooseId, uint256 parent1, uint256 parent2);
    event NameChanged(uint256 mooseId, string mooseName);
    event BioChanged(uint256 mooseId, string mooseBio);

    constructor(string memory name, string memory symbol, uint256 supply, uint256 genCount) MooseERC721(name, symbol, supply, genCount) {}

    function breed(uint256 parent1, uint256 parent2) external mooseOwner(parent1) mooseOwner(parent2) {
        uint256 supply = totalSupply();
        require(supply < maxSupply,                               "Cannot breed any more baby Moose");
        require(parent1 <= maxGenCount && parent2 <= maxGenCount,   "Cannot breed with baby Moose");
        require(parent1 != parent2,                               "Must select two unique parents");

        yieldToken.burn(msg.sender, BREED_PRICE);
        uint256 mooseId = maxGenCount + babyCount + 1;
        babyCount++;
        _safeMint(msg.sender, mooseId);
        emit MooseBreeding(mooseId, parent1, parent2);
    }

    function setYieldToken(address _yield) external onlyOwner {
		yieldToken = IYieldToken(_yield);
	}

	function transferFrom(address from, address to, uint256 tokenId) public override {
		if (tokenId < maxGenCount) {
            yieldToken.updateReward(from, to);
            balanceGenesis[from]--;
            balanceGenesis[to]++;
        }
        ERC721.transferFrom(from, to, tokenId);
	}

	function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
		if (tokenId < maxGenCount) {
            yieldToken.updateReward(from, to);
            balanceGenesis[from]--;
            balanceGenesis[to]++;
        }
        ERC721.safeTransferFrom(from, to, tokenId, _data);
	}
}