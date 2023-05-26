// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MutantApeYachtClub {
    function ownerOf(uint256) public returns (address) {}
}

contract FullBodyApeClub {
    function ownerOf(uint256) public returns (address) {}

    function balanceOf(address) public returns (uint256) {}
}

enum MintMode {
    Closed,
    Presale,
    Public
}

contract FullBodyMutantClub is ERC721Enumerable, Ownable {
    uint256 public maxTokens = 4444;
    uint256 public tokenPrice = 80000000000000000;
    uint256 public discountPer3 = 30000000000000000;

    MintMode public mintMode = MintMode.Closed;
    bool canRemoveMinions = false;

    string _baseTokenURI;

    MutantApeYachtClub maycContract;
    FullBodyApeClub fbacContract;

    mapping(uint256 => uint256) public versionsMinted;
    mapping(uint256 => uint256) public mutantNumber;
    mapping(uint256 => bool) public hasMinion;

    mapping(address => bool) public whitelist;

    event MinionRemoved(uint256 token);

    constructor(
        string memory baseURI,
        address maycAddress,
        address fbacAddress
    ) ERC721("FullBodyMutantClub", "FBMC") {
        _baseTokenURI = baseURI;
        maycContract = MutantApeYachtClub(maycAddress);
        fbacContract = FullBodyApeClub(fbacAddress);
    }

    function mint(uint256[] memory mutants) public payable {
        require(mintMode != MintMode.Closed, "Minting is closed");
        require(mutants.length <= 25, "Can't mint more than 25 at once");
        require(
            totalSupply() + mutants.length <= maxTokens,
            "Can't fulfil requested tokens"
        );

        require(
            msg.value >=
                (tokenPrice * mutants.length) -
                    ((mutants.length / 3) * discountPer3),
            "Didn't send enough ETH"
        );

        bool hasFBAC = fbacContract.balanceOf(msg.sender) > 0;
        require(
            mintMode == MintMode.Public || hasFBAC || whitelist[msg.sender],
            "You are not on the whitelist"
        );

        uint256 token = totalSupply();
        for (uint256 i = 0; i < mutants.length; i++) {
            uint256 mutant = mutants[i];
            require(
                maycContract.ownerOf(mutant) == msg.sender,
                "Not the owner of this mutant"
            );
            require(
                versionsMinted[mutant] < 3,
                "All versions of this mutant have been minted"
            );
            token++;
            versionsMinted[mutant]++;
            mutantNumber[token] = mutant;
            if (hasFBAC) hasMinion[token] = true;
            _safeMint(msg.sender, token);
        }
    }

    // In case someone doesn't like their cute little minion
    // Can only be done when this feature is enabled
    function removeMinion(uint256 token) public {
        require(canRemoveMinions, "Collection has been finalized");
        require(ownerOf(token) == msg.sender, "Not the owner");
        hasMinion[token] = false;
        emit MinionRemoved(token);
    }

    function send(uint256[] memory mutants) public onlyOwner {
        require(mutants.length <= 25, "Can't mint more than 25 at once");
        require(
            totalSupply() + mutants.length <= maxTokens,
            "Can't fulfil requested tokens"
        );

        uint256 token = 0;
        for (uint256 i = 0; i < mutants.length; i++) {
            uint256 mutant = mutants[i];
            require(
                versionsMinted[mutant] < 3,
                "All versions of this mutant have been minted"
            );
            token = totalSupply() + 1;
            versionsMinted[mutant]++;
            mutantNumber[token] = mutant;
            address owner = maycContract.ownerOf(mutant);
            if (fbacContract.balanceOf(owner) > 0) hasMinion[token] = true;
            _safeMint(owner, token);
        }
    }

    function startPresale() external onlyOwner {
        mintMode = MintMode.Presale;
    }

    function startPublic() external onlyOwner {
        mintMode = MintMode.Public;
    }

    function close() external onlyOwner {
        mintMode = MintMode.Closed;
    }

    function addToWhitelist(address[] memory addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = true;
        }
    }

    function setTokenPrice(uint256 price) external onlyOwner {
        tokenPrice = price;
    }

    function setDiscountPer3(uint256 discount) external onlyOwner {
        discountPer3 = discount;
    }

    function setMAYCContract(address mayc) external onlyOwner {
        maycContract = MutantApeYachtClub(mayc);
    }

    function setFBACContract(address fbac) external onlyOwner {
        fbacContract = FullBodyApeClub(fbac);
    }

    function toggleRemoveMinions(bool enabled) external onlyOwner {
        canRemoveMinions = enabled;
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

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function getBaseURI() external view onlyOwner returns (string memory) {
        return _baseTokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}