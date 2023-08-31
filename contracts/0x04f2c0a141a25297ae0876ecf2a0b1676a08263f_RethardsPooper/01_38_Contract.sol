// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author sberto.eth
/// @title RethardsPooper contract
/// @notice This contract is used for the Rethards NFTs, it allows for free minting of a set 
///         amount of NFTs per address and then charges a fee for each additional mint after that. 

import "@thirdweb-dev/contracts/base/ERC721LazyMint.sol";
import "@thirdweb-dev/contracts/extension/PrimarySale.sol";
import "@thirdweb-dev/contracts/lib/CurrencyTransferLib.sol";
import "@thirdweb-dev/contracts/lib/MerkleProof.sol";

/*
   ,;;;;;;;;;;;.
 ,;;;;;;;;;`````)
,;;;;;;;;'    (@)               ,',
;;;;;;;;')       \               ,
;;;;;;;;_}       _)            ',
;;;;;;'        _;_______________
`;;;;;        ;_.---------------'
  `;;;         (
    `;.        )
      `:._   .'                     Sberto.eth, 2023
         )`''`'-.                  
         |`-'
         |   ,'
         |  /
         | /
         |/
         '
         ;
         ;
         ;
         ;
         ;
         ;
         ;
         ; 
         */


contract RethardsPooper is ERC721LazyMint, PrimarySale {
    struct ClaimerProofs {
        address claimer;
        bytes32[][] proofs;
    }

    ClaimerProofs[] public claimerProofs;
    bytes32 public merkleRoot;
    bool public merkleProofEnabled = true;

    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        address _saleRecipient,
        uint256 _pricePerToken,
        uint256 _mintForFree,
        bytes32 _merkleRoot
    ) ERC721LazyMint(_name, _symbol, _royaltyRecipient, _royaltyBps) {
        _setupPrimarySaleRecipient(_saleRecipient);
        pricePerToken = _pricePerToken;
        mintForFree = _mintForFree;
        merkleRoot = _merkleRoot;
    }

    mapping(address => uint256) public numClaimedForFree;
    mapping(address => uint256) public numOwnedTokens; 
    uint256 public pricePerToken;
    uint256 public mintForFree;
    uint256 public maxClaimQuantity = 25; // Maximum number of NFTs that can be claimed per wallet

    function _canLazyMint() internal view override returns (bool) {
        return msg.sender == owner();
    }

    function _transferTokensOnClaim(address _receiver, uint256 _quantity)
        internal
        virtual
        override
        returns (uint256 startTokenId)
    {
        require(_quantity <= maxClaimQuantity, "Exceeded maximum claim quantity");
        require(numOwnedTokens[_receiver] + _quantity <= maxClaimQuantity, "Exceeded maximum claim quantity");

        startTokenId = super._transferTokensOnClaim(_receiver, _quantity);
        _collectPrice(_receiver, _quantity);
        numOwnedTokens[_receiver] += _quantity; // Updates the total owned tokens for the receiver
    }

    function setMaxClaimQuantity(uint256 _newMaxClaimQuantity) external {
        require(msg.sender == owner(), "Not authorized");
        maxClaimQuantity = _newMaxClaimQuantity;
    }

    function _collectPrice(address _receiver, uint256 _quantity) private {
        uint256 freeAllowance = mintForFree - numClaimedForFree[_receiver];
        uint256 freeQuantity = _quantity > freeAllowance ? freeAllowance : _quantity;
        uint256 paidQuantity = _quantity > freeQuantity ? (_quantity - freeQuantity) : 0;
        uint256 totalPrice = paidQuantity * pricePerToken;
        if (paidQuantity > 0) {
            require(msg.value == totalPrice, "Incorrect payment amount");
        }
        CurrencyTransferLib.safeTransferNativeToken(primarySaleRecipient(), totalPrice);
        numClaimedForFree[_receiver] += freeQuantity;
    }

    function priceForAddress(address _address, uint256 _quantity)
        external
        view
        returns (uint256 price)
    {
        uint256 freeAllowance = mintForFree - numClaimedForFree[_address];
        uint256 freeQuantity = _quantity > freeAllowance ? freeAllowance : _quantity;
        uint256 paidQuantity = _quantity > freeQuantity ? (_quantity - freeQuantity) : 0;
        price = paidQuantity * pricePerToken;
        return price;
    }

    function _canSetPrimarySaleRecipient() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    function setPricePerToken(uint256 _newPrice) external {
        require(msg.sender == owner(), "Not authorized");
        pricePerToken = _newPrice;
    }

    function setMintForFree(uint256 _newMintForFree) external {
        require(msg.sender == owner(), "Not authorized");
        mintForFree = _newMintForFree;
    }

    function setMerkleRoot(bytes32 _newMerkleRoot) external {
        require(msg.sender == owner(), "Not authorized");
        merkleRoot = _newMerkleRoot;
    }

    function toggleMerkleProof() external onlyOwner {
        merkleProofEnabled = !merkleProofEnabled;
    }

    function getMerkleRoot() public view returns (bytes32) {
        return merkleRoot;
    }

    function verifyClaimProof(
    address _claimer,
    uint256 _quantity,
    uint256 _proofIndex
) public view {
    require(merkleProofEnabled, "Merkle proof checking is not enabled");
    bytes32 root = merkleRoot;
    bytes32 leaf = getLeafHash(_claimer);
    require(_proofIndex < claimerProofs.length, "Invalid proof index");
    require(
        _verifyMerkleProof(claimerProofs[_proofIndex].proofs, root, leaf),
        "Claim not verified"
    );
    super.verifyClaim(_claimer, _quantity);
}

function setProofs(address[] memory _claimers, bytes32[][] memory _proofs) external onlyOwner {
    require(_claimers.length == _proofs.length, "Array lengths do not match");

    for (uint256 i = 0; i < _claimers.length; i++) {
        address claimer = _claimers[i];

        bool found = false;
        for (uint256 j = 0; j < claimerProofs.length; j++) {
            if (claimerProofs[j].claimer == claimer) {
                claimerProofs[j].proofs[0] = _proofs[i];
                found = true;
                break;
            }
        }

        if (!found) {
            bytes32[][] memory singleProof = new bytes32[][](1);
            singleProof[0] = _proofs[i];
            
            ClaimerProofs memory newClaimerProofs = ClaimerProofs({
                claimer: claimer,
                proofs: singleProof
            });
            
            claimerProofs.push(newClaimerProofs);
        }
    }
}

    function verifyClaim(address _claimer, uint256 _quantity) public view virtual override {
    if (merkleProofEnabled) {
        require(merkleProofEnabled, "Merkle proof checking is not enabled");
        uint256 proofIndex = getProofIndex(_claimer);
        verifyClaimProof(_claimer, _quantity, proofIndex);
    }
    // If merkleProofEnabled is false, the function will allow the claim without verification
}

    function getProofIndex(address _claimer) internal view returns (uint256) {
        for (uint256 i = 0; i < claimerProofs.length; i++) {
            if (claimerProofs[i].claimer == _claimer) {
                return i;
            }
        }
        revert("No proof found for the given claimer");
    }

    function getLeafHash(address _claimer) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_claimer));
    }

   
    function _verifyMerkleProof(
        bytes32[][] memory _proofs,
        bytes32 _root,
        bytes32 _leaf
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < _proofs.length; i++) {
            (bool success, ) = MerkleProof.verify(_proofs[i], _root, _leaf);
            if (success) {
                return true;
            }
        }
        return false;
    }
}