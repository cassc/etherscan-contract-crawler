//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "erc721a/contracts/ERC721A.sol";

contract PATHFINDERS is ERC721A, Ownable, PaymentSplitter {
    using Strings for uint256;

    string private _baseTokenURI = "ipfs://QmZxS9MEU7ubxy5XYhZTnodADMf4FYKvFRGLocNSVW37Gq/";
    bytes32 private whitelist;

    uint256 public cost = 0.15 ether;
    uint256 public maxSupply = 7878;
    uint256 public maxByWallet = 2;

    uint256 public step = 1;

    // 1 = closed (not started or soldOut)
    // 2 = private sale (Whitelist + raffle)
    // 3 = Opensale

    constructor(address[] memory _payees, uint256[] memory _shares)
        ERC721A("PATHFINDERS", "PATH")
        PaymentSplitter(_payees, _shares)
    {}

    function mint(uint256 amount, bytes32[] calldata proof) public payable {
        require(step != 1, "Mint is closed");
        if (step == 2) {
            require(isWhitelisted(msg.sender, proof), "Not selected");
        }
        require(totalSupply() + amount <= maxSupply, "Sold out !");

        uint256 walletBalance = _numberMinted(msg.sender);
        require(
            walletBalance + amount <= maxByWallet,
            "Maximum of two NFT by wallet"
        );
        require(msg.value >= cost * amount, "Not enough ether sended");

        _safeMint(msg.sender, amount);
    }

    function gift(uint256 amount, address to) public onlyOwner {
        require(totalSupply() + amount <= maxSupply, "Sold out");

        _safeMint(to, amount);
    }

    function isWhitelisted(address account, bytes32[] calldata proof)
        internal
        view
        returns (bool)
    {
        return _verify(_leaf(account), proof, whitelist);
    }

    function setWhitelist(bytes32 whitelistroot) public onlyOwner {
        whitelist = whitelistroot;
    }

    function switchStep(uint256 newStep) public onlyOwner {
        step = newStep;
    }

    function setCost(uint256 newCost) public onlyOwner {
        cost = newCost;
    }

    function setMaxByWallet(uint256 newMaxByWallet) public onlyOwner {
        maxByWallet = newMaxByWallet;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    function _baseUri() internal view virtual returns (string memory) {
        return _baseTokenURI;
    }

    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(
        bytes32 leaf,
        bytes32[] memory proof,
        bytes32 root
    ) internal pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        string memory currentBaseURI = _baseUri();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }
}