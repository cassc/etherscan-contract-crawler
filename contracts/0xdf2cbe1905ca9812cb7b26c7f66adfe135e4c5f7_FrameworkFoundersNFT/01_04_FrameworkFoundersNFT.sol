// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";

/// @title FrameworkFoundersNFT
/// @author rajivpoc <[email protected]>
/// @notice Ownership enables access to token-gated content.
/// @notice Non-transferrable and can be burned at any time.
contract FrameworkFoundersNFT is ERC721, Ownable {
    string public baseURI;
    uint256 public totalSupply;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    ) ERC721(_name, _symbol) {
        baseURI = _baseURI;
    }

    function mint(address founder) public onlyOwner {
        require(balanceOf[founder] == 0, "ONE_MINT_PER_ADDRESS");
        unchecked {
            _mint(founder, totalSupply);
            ++totalSupply;
        }
    }

    function burn(uint256 id) public onlyOwner {
        unchecked {
            _burn(id);
            --totalSupply;
        }
    }

    function approve(address spender, uint256 id) public override onlyOwner {
        address owner = ownerOf[id];

        require(
            msg.sender == owner || isApprovedForAll[owner][msg.sender],
            "NOT_AUTHORIZED"
        );

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyOwner
    {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override onlyOwner {
        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function tokenURI(uint256 tokenID)
        public
        view
        override
        returns (string memory)
    {
        require(ownerOf[tokenID] != address(0), "NOT_MINTED");
        return string(abi.encodePacked(baseURI));
    }
}