// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IJuice {
	function ownerOf(uint256 tokenId) external view returns (address owner);

	function burn(uint256 tokenId) external;
}

contract CloneMachineUpgrade is IJuice, ReentrancyGuard, Pausable, Ownable {
    using ECDSA for bytes32;

    // original juice contract
    IJuice public realJuice;
    
    // original clone contract
    IERC721 public cloneContract;

    mapping (uint256 => bool) public copiedD1Clones;
    mapping (uint256 => uint256) public cloneToLevel; // 0 - d1, 2 - d2, 3 - d3

    uint256 public gangForD2;
    uint256 public gangForD3;

    IERC20 private gangToken;

    bool public gangEnabled;

    address private signerAddress;

    event CloneD2Upgraded(
        address owner,
        uint256 juiceId,
        uint256 upgradedCloneId,
        uint256 copiedCloneId
    );

    event CloneD3Upgraded(
        address owner,
        uint256 juiceId,
        uint256 cloneId
    );

    function ownerOf(uint256 tokenId) external view returns (address owner) {
        return realJuice.ownerOf(tokenId);
    }

	function burn(uint256 tokenId) external {
        require(
            tx.origin == address(cloneContract) || msg.sender == address(cloneContract), 
            "can't burn"
        );
        realJuice.burn(tokenId);
    }

    function isD2Eligible(
        address holder,
        uint256 upgradedCloneId, // this clone will become D2
        uint256 copiedCloneId, // this clone's traits will be copied
        uint256 juiceId
    ) public view returns (bool) {
        return
            (paused() == false) &&
            (cloneToLevel[upgradedCloneId] == 0) &&
            (cloneToLevel[copiedCloneId] == 0) &&
            (upgradedCloneId != copiedCloneId) &&
            (cloneContract.ownerOf(upgradedCloneId) == holder) &&
            (cloneContract.ownerOf(copiedCloneId) == holder) &&
            (realJuice.ownerOf(juiceId) == holder) &&
            (!copiedD1Clones[copiedCloneId]);
    }

    function upgradeD2Clone(
        bytes memory sig,
        uint256 upgradedCloneId, // this clone will become D2
        uint256 copiedCloneId, // this clone's traits will be copied
        uint256 juiceId
    ) external nonReentrant {
        bytes32 hash = hashD2Upgrade(msg.sender, upgradedCloneId, copiedCloneId, juiceId);
        require(matchAddresSigner(hash, sig), "wrong sig");

        require(isD2Eligible(msg.sender, upgradedCloneId, copiedCloneId, juiceId), "not eligible");

        if (gangEnabled) {
            require(gangToken.transferFrom(msg.sender, address(this), gangForD2), "gang transfer issue");
        }

        realJuice.burn(juiceId);

        copiedD1Clones[copiedCloneId] = true;
        cloneToLevel[upgradedCloneId] = 2;

        emit CloneD2Upgraded(msg.sender, juiceId, upgradedCloneId, copiedCloneId);
    }

    function isD3Eligible(
        address holder,
        uint256 cloneId,
        uint256 juiceId
    ) public view returns (bool) {
        return
            (paused() == false) &&
            (cloneToLevel[cloneId] == 0) &&
            (cloneContract.ownerOf(cloneId) == holder) &&
            (realJuice.ownerOf(juiceId) == holder);
    }

    function upgradeD3Clone(
        bytes memory sig,
        uint256 cloneId,
        uint256 juiceId
    ) external nonReentrant {
        bytes32 hash = hashD3Upgrade(msg.sender, cloneId, juiceId);
        require(matchAddresSigner(hash, sig), "wrong sig");

        require(isD3Eligible(msg.sender, cloneId, juiceId), "not eligible");
        
        if (gangEnabled) {
            require(gangToken.transferFrom(msg.sender, address(this), gangForD3), "gang transfer issue");
        }

        realJuice.burn(juiceId);

        cloneToLevel[cloneId] = 3;

        emit CloneD3Upgraded(msg.sender, juiceId, cloneId);
    }

    function hashD2Upgrade(
		address sender,
        uint256 upgradedCloneId,
        uint256 copiedCloneId,
		uint256 juiceId
	) private pure returns (bytes32) {
		bytes32 hash = ECDSA.toEthSignedMessageHash(
			keccak256(abi.encodePacked(sender, upgradedCloneId, copiedCloneId, juiceId))
		);
		return hash;
	}

    function hashD3Upgrade(
		address sender,
        uint256 cloneId,
		uint256 juiceId
	) private pure returns (bytes32) {
		bytes32 hash = ECDSA.toEthSignedMessageHash(
			keccak256(abi.encodePacked(sender, cloneId, juiceId))
		);
		return hash;
	}

    function matchAddresSigner(
        bytes32 hash,
        bytes memory signature
    ) private view returns (bool) {
		return signerAddress == hash.recover(signature);
	}

    function setup(
        address _realJuice,
        address _cloneContract,
        address _signer
    ) external onlyOwner {
        realJuice = IJuice(_realJuice);
        cloneContract = IERC721(_cloneContract);
        signerAddress = _signer;
    }

    function setupGang(
        address _gangToken
    ) external onlyOwner {
        gangToken = IERC20(_gangToken);
    }

    function setupGangPricing(
        uint256 _gangForD2,
        uint256 _gangForD3
    ) external onlyOwner {
        gangForD2 = _gangForD2;
        gangForD3 = _gangForD3;
    }

    function setGangEnabled(bool _enabled) external onlyOwner {
        gangEnabled = _enabled;
    }

	function reclaimERC20(address _tokenContract, uint256 _amount) external onlyOwner {
		require(IERC20(_tokenContract).transfer(msg.sender, _amount), "transfer failed");
	}

	function reclaimERC721(IERC721 erc721Token, uint256 id) external onlyOwner {
		erc721Token.safeTransferFrom(address(this), msg.sender, id);
	}

	function reclaimERC1155(
		IERC1155 erc1155Token,
		uint256 id,
		uint256 amount
	) external onlyOwner {
		erc1155Token.safeTransferFrom(address(this), msg.sender, id, amount, "");
	}

    function withdraw() external onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

    function setPaused(bool isPaused) external onlyOwner {
        if (isPaused) _pause();
        else _unpause();
    }

    function getCloneLevels(
        uint256[] calldata cloneIds
    ) external view returns(
        uint256[] memory, 
        uint256, 
        uint256[] memory, 
        uint256, 
        uint256[] memory, 
        uint256
    )  {
        uint256[] memory d1 = new uint256[](cloneIds.length);
        uint256[] memory d2 = new uint256[](cloneIds.length);
        uint256[] memory d3 = new uint256[](cloneIds.length);

        uint256 d1Counter = 0;
        uint256 d2Counter = 0;
        uint256 d3Counter = 0;

        for (uint256 i = 0; i < cloneIds.length; i++) {
            uint256 current = cloneIds[i];
            if (cloneToLevel[current] == 0) {
                d1[d1Counter] = current;
                d1Counter++;
            } else if (cloneToLevel[current] == 2) {
                d2[d2Counter] = current;
                d2Counter++;
            }
            else if (cloneToLevel[current] == 3) {
                d3[d3Counter] = current;
                d3Counter++;
            } 
        }

        uint256[] memory d1Clones = new uint256[](d1Counter);
        for (uint256 i = 0; i < d1Counter; i++) {
            d1Clones[i] = d1[i];
        }

        uint256[] memory d2Clones = new uint256[](d2Counter);
        for (uint256 i = 0; i < d2Counter; i++) {
            d2Clones[i] = d2[i];
        }

        uint256[] memory d3Clones = new uint256[](d3Counter);
        for (uint256 i = 0; i < d3Counter; i++) {
            d3Clones[i] = d3[i];
        }

        return (
            d1Clones, d1Counter,
            d2Clones, d2Counter,
            d3Clones, d3Counter
        );
    }

}