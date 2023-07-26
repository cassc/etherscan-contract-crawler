// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "../../utils/interfaces/IERC20Fixed.sol";
import "../UniqRedeem/IUniqRedeemV3.sol";
import "../OwnershipHolder/IOwnershipHolder.sol";

contract UniqPaymentProxyV3 is Ownable, EIP712, ERC1155Holder, IERC721Receiver {
    // ----- EVENTS ----- //
    event Executed(address indexed executor, uint256 indexed nonce);

    // ----- STRUCTURES ----- //
    struct ERC721TokenData {
        address tokenAddress;
        uint256 id;
        address receiver;
        uint256 network;
        RedeemTypes toBurn;
        uint256 purpose;
    }

    struct ERC1155TokenData {
        address tokenAddress;
        uint256 id;
        uint256 amount;
        address receiver;
        uint256 network;
        RedeemTypes toBurn;
        uint256 purpose;
    }

    enum RedeemTypes {
        MintOnly, //0
        MintAndRedeem, //1
        RedeemOnly //2
    }

    // ----- VARIABLES ----- //
    uint256 internal _networkId;
    mapping(uint256 => bool) public _isNonceUsed;
    address public signer;
    IUniqRedeemV3 public redeem;
    IOwnershipHolder public ownershipHolder;

    // ----- CONSTRUCTOR ----- //
    constructor(
        uint256 _pnetworkId,
        address _signer,
        address _redeem,
        address _ownershipHolder
    ) EIP712("Uniqly", "1") {
        _networkId = _pnetworkId;
        signer = _signer;
        redeem = IUniqRedeemV3(_redeem);
        ownershipHolder = IOwnershipHolder(_ownershipHolder);
    }

    function setRedeemAddress(IUniqRedeemV3 _redeemAddress) external onlyOwner {
        redeem = _redeemAddress;
    }

    function setOwnershipHolderAddress(
        IOwnershipHolder _ownershipHolder
    ) external onlyOwner {
        ownershipHolder = _ownershipHolder;
    }

    function _sendTokens(
        address _paymentToken,
        uint256[] memory _amount,
        address[] memory _paymentReceiver
    ) internal {
        uint256 len = _amount.length;
        require(len == _paymentReceiver.length, "Length mimatch pt");
        if (_paymentToken == address(0)) {
            uint256 sum;
            for (uint256 i = 0; i < len; i++) {
                sum += _amount[i];
            }
            require(msg.value >= sum, "Not enough ether");
            if (sum < msg.value) {
                payable(msg.sender).transfer(msg.value - sum);
            }
        }
        for (uint256 i = 0; i < len; i++) {
            if (_paymentToken == address(0)) {
                if (_amount[i] > 0) {
                    payable(_paymentReceiver[i]).transfer(_amount[i]);
                }
            } else {
                if (_amount[i] > 0) {
                    IERC20Fixed(_paymentToken).transferFrom(
                        msg.sender,
                        _paymentReceiver[i],
                        _amount[i]
                    );
                }
            }
        }
    }

    function _redeemTokens(
        address _contractAddress,
        uint256[] memory _tokenIds,
        uint256[] memory _purposes,
        uint256[] memory _networks
    ) internal {
        address[] memory contractAddresses = new address[](_tokenIds.length);
        string[] memory names = new string[](_tokenIds.length);
        address[] memory owners = new address[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            contractAddresses[i] = _contractAddress;
            names[i] = "UniqlyPPV3";
            owners[i] = address(this);
        }
        redeem.redeemTokensAsAdmin(
            contractAddresses,
            _tokenIds,
            _purposes,
            owners,
            names,
            _networks
        );
    }

    function _processERC721(ERC721TokenData[] memory erc721Tokens) internal {
        uint256[] memory ids = new uint256[](erc721Tokens.length);
        address[] memory receivers = new address[](erc721Tokens.length);
        uint256[] memory purposes = new uint256[](erc721Tokens.length);
        uint256[] memory networks = new uint256[](erc721Tokens.length);
        //Redeem only scenario
        if (erc721Tokens[0].toBurn == RedeemTypes.RedeemOnly) {
            if (address(redeem) != address(0)) {
                for (uint256 i = 0; i < erc721Tokens.length; i++) {
                    require(erc721Tokens[i].purpose != 0, "Purpose error");
                    ids[i] = erc721Tokens[i].id;
                    purposes[i] = erc721Tokens[i].purpose;
                    networks[i] = erc721Tokens[i].network;
                }
                _redeemTokens(
                    erc721Tokens[0].tokenAddress,
                    ids,
                    purposes,
                    networks
                );
            }
        }
        //Mint and burn scenario
        else if (erc721Tokens[0].network == _networkId) {
            for (uint256 i = 0; i < erc721Tokens.length; i++) {
                if (erc721Tokens[0].toBurn == RedeemTypes.MintAndRedeem) {
                    require(erc721Tokens[i].purpose != 0, "Purpose error");
                }
                ids[i] = erc721Tokens[i].id;
                receivers[i] = erc721Tokens[i].receiver;
                purposes[i] = erc721Tokens[i].purpose;
                networks[i] = erc721Tokens[i].network;
            }
            try
                ownershipHolder.pBatchMintSelectedIds(
                    ids,
                    receivers,
                    erc721Tokens[0].tokenAddress
                )
            {} catch {
                bytes memory bt = abi.encodePacked(
                    erc721Tokens[0].tokenAddress,
                    networks,
                    ids,
                    receivers,
                    block.number
                );
                ownershipHolder.pMintNFTTokens(
                    erc721Tokens[0].tokenAddress,
                    receivers[0],
                    8888,
                    ids,
                    _networkId,
                    bt
                );
            }
            if (
                erc721Tokens[0].toBurn == RedeemTypes.MintAndRedeem &&
                address(redeem) != address(0)
            ) {
                _redeemTokens(
                    erc721Tokens[0].tokenAddress,
                    ids,
                    purposes,
                    networks
                );
            }
        }
    }

    function _processERC1155(ERC1155TokenData[] memory erc1155Tokens) internal {
        uint256[] memory ids = new uint256[](erc1155Tokens.length);
        uint256[] memory amounts = new uint256[](erc1155Tokens.length);
        address[] memory receivers = new address[](erc1155Tokens.length);
        bool[] memory burn = new bool[](erc1155Tokens.length);
        for (uint256 i = 0; i < erc1155Tokens.length; i++) {
            ids[i] = erc1155Tokens[i].id;
            receivers[i] = erc1155Tokens[i].receiver;
            amounts[i] = erc1155Tokens[i].amount;
            burn[i] = erc1155Tokens[i].toBurn == RedeemTypes.MintAndRedeem
                ? true
                : false;
        }
        //Burn Scenario
        if (erc1155Tokens[0].toBurn == RedeemTypes.RedeemOnly) {
            //TODO: Redeem for erc1155?
            ///require(erc1155Tokens[0].purpose != 0, "Purpose is zero");
            ownershipHolder.pBatchBurnFrom1155(
                erc1155Tokens[0].tokenAddress,
                ids,
                amounts,
                erc1155Tokens[0].receiver
            );
            return;
        }
        //Mint or Mint-and-burn scenario
        if (erc1155Tokens[0].network == _networkId) {
            //TODO: Redeem for erc1155?
            ///require(erc1155Tokens[0].purpose != 0, "Purpose is zero");
            ownershipHolder.pBatchMintAndBurn1155(
                erc1155Tokens[0].tokenAddress,
                ids,
                amounts,
                burn,
                receivers[0]
            );
        }
    }

    function _processBatch(
        uint256 network,
        address tokenContractAddress,
        uint256[] memory tokenIds,
        uint256[] memory erc1155tokenAmounts,
        RedeemTypes toBurn,
        address receiver,
        uint256 startBatchIndex,
        uint256 endBatchIndex,
        uint256 purpose
    ) internal {
        uint256 elSum = endBatchIndex - startBatchIndex;
        uint256 elInd;
        if (erc1155tokenAmounts[startBatchIndex] == 0) {
            ERC721TokenData[] memory erc721Tokens = new ERC721TokenData[](
                elSum
            );
            for (uint256 i = startBatchIndex; i < endBatchIndex; i++) {
                erc721Tokens[elInd] = ERC721TokenData({
                    tokenAddress: tokenContractAddress,
                    receiver: receiver,
                    id: tokenIds[i],
                    network: network,
                    toBurn: toBurn,
                    purpose: purpose
                });
                elInd++;
            }
            _processERC721(erc721Tokens);
        } else {
            ERC1155TokenData[] memory erc1155Tokens = new ERC1155TokenData[](
                elSum
            );
            for (uint256 i = startBatchIndex; i < endBatchIndex; i++) {
                erc1155Tokens[elInd] = ERC1155TokenData({
                    tokenAddress: tokenContractAddress,
                    receiver: receiver,
                    amount: erc1155tokenAmounts[i],
                    id: tokenIds[i],
                    network: network,
                    toBurn: toBurn,
                    purpose: purpose
                });
                elInd++;
            }
            _processERC1155(erc1155Tokens);
        }
    }

    function _processTokens(
        uint256[] memory networks,
        address[] memory tokenContractAddreses,
        uint256[] memory tokenIds,
        uint256[] memory erc1155tokenAmounts,
        RedeemTypes[] memory toBurn,
        uint256[] memory purposes,
        address receiver
    ) internal {
        uint256 len = tokenContractAddreses.length;
        require(
            len == networks.length &&
                len == tokenIds.length &&
                len == erc1155tokenAmounts.length &&
                len == toBurn.length &&
                len == purposes.length,
            "UPP: Check arrays lenghts"
        );
        if (len == 0) return;
        uint256 elSum;
        for (uint256 i = 0; i < len; i++) {
            if (elSum > 0) {
                if (
                    tokenContractAddreses[i] != tokenContractAddreses[i - 1] ||
                    networks[i] != networks[i - 1] ||
                    toBurn[i] != toBurn[i - 1] ||
                    purposes[i] != purposes[i - 1]
                ) {
                    _processBatch(
                        networks[i - 1],
                        tokenContractAddreses[i - 1],
                        tokenIds,
                        erc1155tokenAmounts,
                        toBurn[i - 1],
                        receiver,
                        i - elSum,
                        i,
                        purposes[i - 1]
                    );
                    elSum = 0;
                    i--;
                    continue;
                }
            }
            elSum++;
        }

        if (elSum > 0) {
            _processBatch(
                networks[len - 1],
                tokenContractAddreses[len - 1],
                tokenIds,
                erc1155tokenAmounts,
                toBurn[len - 1],
                receiver,
                len - elSum,
                len,
                purposes[len - 1]
            );
        }
    }

    // ----- PUBLIC METHODS ----- //
    function execTransaction(
        uint256[] memory networks,
        address[] memory tokenContractAddresses,
        uint256[] memory tokenIds,
        uint256[] memory erc1155TokenAmounts,
        RedeemTypes[] memory toBurn,
        uint256[] memory purposes,
        uint256[] memory ptAmounts, //amount to send
        address[] memory ptReceivers, //tokens receivers
        address[] memory addresses, //0 - paymentToken address, 1- nft receiver address
        uint256 nonce,
        uint256 deadline,
        bytes memory signature
    ) external payable {
        require(deadline > block.timestamp, "UPP: Transaction timed out");
        require(!_isNonceUsed[nonce], "UPP: Nonce already used");
        bytes32 typedHash = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "ExecData(uint256[] networks,address[] tokenContractAddresses,uint256[] tokenIds,uint256[] erc1155TokenAmounts,uint256[] toBurn,uint256[] purposes,uint256[] ptAmounts,address[] ptReceivers,address[] addresses,uint256 nonce,uint256 deadline)"
                    ),
                    keccak256(abi.encodePacked(networks)),
                    keccak256(abi.encodePacked(tokenContractAddresses)),
                    keccak256(abi.encodePacked(tokenIds)),
                    keccak256(abi.encodePacked(erc1155TokenAmounts)),
                    keccak256(abi.encodePacked(toBurn)),
                    keccak256(abi.encodePacked(purposes)),
                    keccak256(abi.encodePacked(ptAmounts)),
                    keccak256(abi.encodePacked(ptReceivers)),
                    keccak256(abi.encodePacked(addresses)),
                    nonce,
                    deadline
                )
            )
        );
        require(
            ECDSA.recover(typedHash, signature) == signer,
            "UPP: Signature Mismatch"
        );
        _isNonceUsed[nonce] = true;

        _sendTokens(addresses[0], ptAmounts, ptReceivers);

        _processTokens(
            networks,
            tokenContractAddresses,
            tokenIds,
            erc1155TokenAmounts,
            toBurn,
            purposes,
            addresses[1]
        );

        emit Executed(msg.sender, nonce);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // ----- PROXY METHODS ----- //
    function pEditClaimingAddress(
        address _contractAddress,
        address _newAddress
    ) external onlyOwner {
        ownershipHolder.pEditClaimingAdress(_contractAddress, _newAddress);
    }

    function pEditRoyaltyFee(
        address _contractAddress,
        uint256 _newFee
    ) external onlyOwner {
        ownershipHolder.pEditRoyaltyFee(_contractAddress, _newFee);
    }

    function pEditTokenUri(
        address _contractAddress,
        string memory _ttokenUri
    ) external onlyOwner {
        ownershipHolder.pEditTokenUri(_contractAddress, _ttokenUri);
    }

    function pRecoverERC20(
        address _contractAddress,
        address token
    ) external onlyOwner {
        ownershipHolder.pRecoverERC20(_contractAddress, token);
    }

    function pTransferOwnership(
        address _contractAddress,
        address newOwner
    ) external onlyOwner {
        ownershipHolder.pTransferOwnership(_contractAddress, newOwner);
    }

    function pBatchMintSelectedIds(
        uint256[] memory _ids,
        address[] memory _addresses,
        address _contractAddress
    ) external onlyOwner {
        ownershipHolder.pBatchMintSelectedIds(
            _ids,
            _addresses,
            _contractAddress
        );
    }

    function pMintNFTTokens(
        address _contractAddress,
        address _requesterAddress,
        uint256 _bundleId,
        uint256[] memory _tokenIds,
        uint256 _chainId,
        bytes memory _transactionHash
    ) external onlyOwner {
        ownershipHolder.pMintNFTTokens(
            _contractAddress,
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
    ) external onlyOwner {
        ownershipHolder.pMintNextToken(_contractAddress, _receiver);
    }

    function pSetNewPaymentProxy(
        address _contractAddress,
        address _newPP
    ) external onlyOwner {
        ownershipHolder.pSetNewPaymentProxy(_contractAddress, _newPP);
    }

    function pSetNewAdministrator(
        address _contractAddress,
        address _newAdmin
    ) external onlyOwner {
        ownershipHolder.pSetNewAdministrator(_contractAddress, _newAdmin);
    }

    // ----- OWNERS METHODS ----- //

    function withdrawTokens(address token) external onlyOwner {
        uint256 val = IERC20(token).balanceOf(address(this));
        require(val != 0, "Nothing to recover");
        // use interface that not return value (USDT case)
        IERC20Fixed(token).transfer(msg.sender, val);
    }

    receive() external payable {}

    function wthdrawETH() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}