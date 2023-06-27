// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import "./ERC721A/ERC721A.sol";
import "solmate/auth/Owned.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";

// ░░░░░██╗░█████╗░██╗██╗░░░░░████████╗██╗███╗░░░███╗███████╗░░░░██████╗░░██████╗░
// ░░░░░██║██╔══██╗██║██║░░░░░╚══██╔══╝██║████╗░████║██╔════╝░░░██╔════╝░██╔════╝░
// ░░░░░██║███████║██║██║░░░░░░░░██║░░░██║██╔████╔██║█████╗░░░░░██║░░██╗░██║░░██╗░
// ██╗░░██║██╔══██║██║██║░░░░░░░░██║░░░██║██║╚██╔╝██║██╔══╝░░░░░██║░░╚██╗██║░░╚██╗
// ╚█████╔╝██║░░██║██║███████╗░░░██║░░░██║██║░╚═╝░██║███████╗██╗╚██████╔╝╚██████╔╝
// ░╚════╝░╚═╝░░╚═╝╚═╝╚══════╝░░░╚═╝░░░╚═╝╚═╝░░░░░╚═╝╚══════╝╚═╝░╚═════╝░░╚═════╝░
//
// https://jailtime.gg/
// https://twitter.com/jailtimegg

contract JailTime is ERC721A, Owned {
    using Strings for uint256;

    bool public inSession;
    string public baseURI;
    uint256 public constant MAX_SUPPLY = 5000;
    uint256 public constant MAX_JUDGE_MINT = 50;
    uint256 public reserveMinted;
    address public judgement;
    mapping(address => bool) internal summoned;

    constructor() ERC721A("JailTime", "JAIL") Owned(msg.sender) {}

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        require(_exists(id), "id doesn't exist");
        return string(abi.encodePacked(baseURI, id.toString()));
    }

    function summon() external {
        require(inSession, "Court is not in session");
        require(totalSupply() < MAX_SUPPLY, "All summons distributed");
        require(!summoned[msg.sender], "You have already been summoned");
        summoned[msg.sender] = true;
        _mint(msg.sender, 1);
    }

    function judgeMint(uint256 amount, address recipient) external onlyOwner {
        require(reserveMinted + amount <= MAX_JUDGE_MINT, "Reserves are depleted");        
        reserveMinted = reserveMinted + amount;
        _mint(recipient, amount);
    }

    function burn(uint256 summons) external {
        require(msg.sender == judgement, "Burner is not approved");
        _burn(summons);
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setJudgement(address _judgement) external onlyOwner {
        judgement = _judgement;
    }

    function setSession(bool _session) external onlyOwner {
        inSession = _session;
    }

}