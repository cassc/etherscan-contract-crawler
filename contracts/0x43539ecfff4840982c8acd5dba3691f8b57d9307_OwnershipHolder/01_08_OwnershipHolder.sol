// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../../utils/interfaces/IERC20Fixed.sol";
import "../UniqOperator/IUniqOperator.sol";

contract OwnershipHolder is Ownable {
    modifier ownerOrOperator() {
        require(
            owner() == msg.sender ||
                operator.isOperator(accessLevel, msg.sender),
            "Only owner or proxy allowed"
        );
        _;
    }

    function editAccessLevel(uint256 newLevel) external onlyOwner {
        accessLevel = newLevel;
    }

    // ----- VARIABLES ----- //
    uint256 public accessLevel;
    IUniqOperator public operator;

    // ----- CONSTRUCTOR ----- //
    constructor(IUniqOperator operatorAddress){
        operator = operatorAddress;
        accessLevel = 1;
    }

    // ----- PROXY METHODS ----- //
    function pEditClaimingAddress(
        address _contractAddress,
        address _newAddress
    ) external ownerOrOperator {
        IUniqCollections(_contractAddress).editClaimingAdress(_newAddress);
    }

    function pEditRoyaltyFee(
        address _contractAddress,
        uint256 _newFee
    ) external ownerOrOperator {
        IUniqCollections(_contractAddress).editRoyaltyFee(_newFee);
    }

    function pEditTokenUri(
        address _contractAddress,
        string memory _ttokenUri
    ) external ownerOrOperator {
        IUniqCollections(_contractAddress).editTokenUri(_ttokenUri);
    }

    function pRecoverERC20(
        address _contractAddress,
        address token
    ) external ownerOrOperator {
        IUniqCollections(_contractAddress).recoverERC20(token);
        uint256 val = IERC20(token).balanceOf(address(this));
        require(val > 0, "Nothing to recover");
        IERC20Fixed(token).transfer(owner(), val);
    }

    function pOwner(
        address _contractAddress
    ) external view returns(address) {
        return NFTContract(_contractAddress).owner();
    }

    function pTransferOwnership(
        address _contractAddress,
        address newOwner
    ) external onlyOwner {
        IUniqCollections(_contractAddress).transferOwnership(newOwner);
    }

    function pBatchMintSelectedIds(
        uint256[] memory _ids,
        address[] memory _addresses,
        address _contractAddress
    ) external ownerOrOperator {
        IUniqCollections(_contractAddress).batchMintSelectedIds(
            _ids,
            _addresses
        );
    }

    function pMintNFTTokens(
        address _contractAddress,
        address _requesterAddress,
        uint256 _bundleId,
        uint256[] memory _tokenIds,
        uint256 _chainId,
        bytes memory _transactionHash
    ) external ownerOrOperator {
        NFTContract(_contractAddress).mintNFTTokens(
            _requesterAddress,
            _bundleId,
            _tokenIds,
            _chainId,
            _transactionHash
        );
    }

    function pMintNextToken(
        address _contractAddress,
        address _receiver
    ) external ownerOrOperator {
        IUniqCollections(_contractAddress).mintNextToken(_receiver);
    }

    function pSetNewPaymentProxy(
        address _contractAddress,
        address _newPP
    ) external onlyOwner {
        IUniqCollections(_contractAddress).setPaymentProxy(_newPP);
    }

    function pSetNewAdministrator(
        address _contractAddress,
        address _newAdmin
    ) external ownerOrOperator {
        IUniqCollections(_contractAddress).setAdministrator(_newAdmin);
    }

    function pEditClaimingAdress(
        address _contractAddress,
        address _newAddress
    ) external ownerOrOperator {
        IUniqCollections(_contractAddress).editClaimingAdress(_newAddress);
    }

    function pBurn(
        address _contractAddress,
        uint256 _tokenId
    ) external ownerOrOperator {
        IUniqCollections(_contractAddress).burn(_tokenId);
    }

    function pBatchMintAndBurn1155(
        address _contractAddress,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bool[] memory _burn,
        address _receiver
    ) external ownerOrOperator {
        IUniqCollections1155(_contractAddress).batchMintAndBurn(
            _ids,
            _amounts,
            _burn,
            _receiver
        );
    }

    function pBatchBurnFrom1155(
        address _contractAddress,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        address burner
    ) external ownerOrOperator {
        IUniqCollections1155(_contractAddress).batchBurnFrom(
            _ids,
            _amounts,
            burner
        );
    }

    // ----- OWNERS METHODS ----- //

    function withdrawTokens(address token) external onlyOwner {
        uint256 val = IERC20(token).balanceOf(address(this));
        require(val != 0, "Nothing to recover");
        // use interface that not return value (USDT case)
        IERC20Fixed(token).transfer(msg.sender, val);
    }
}

interface IUniqCollections {
    function editClaimingAdress(address _newAddress) external;

    function editRoyaltyFee(uint256 _newFee) external;

    function batchMintSelectedIds(
        uint256[] memory _ids,
        address[] memory _addresses
    ) external;

    function editTokenUri(string memory _ttokenUri) external;

    function recoverERC20(address token) external;

    function transferOwnership(address newOwner) external;

    function mintNextToken(address _receiver) external;

    function burn(uint256 _tokenId) external;

    function setPaymentProxy(address newPP) external;

    function setAdministrator(address _newOwner) external;
}

interface IUniqCollections1155 {
    function batchMintAndBurn(
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bool[] memory _burn,
        address _receiver
    ) external;

    function batchBurnFrom(
        uint256[] memory _ids,
        uint256[] memory _amounts,
        address burner
    ) external;
}

interface NFTContract {
    function mintNFTTokens(
        address _requesterAddress,
        uint256 _bundleId,
        uint256[] memory _tokenIds,
        uint256 _chainId,
        bytes memory _transactionHash
    ) external;

    function owner() external view returns (address);
}