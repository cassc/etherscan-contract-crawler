// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./AbstractERC1155Factory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract GearPod is AbstractERC1155Factory {
    using ECDSA for bytes32;
    using Counters for Counters.Counter;

    Counters.Counter private podCounter; 

    struct Pod {
        uint256 startWindow;
        uint256 endWindow;
        uint256 price;
        mapping(address => uint256) amountMinted;
        string tokenUri;
    }
    mapping(uint256 => Pod) public pods;

    IERC20 immutable POW;
    address paymentReceiver;

    address signer;

    error windowClosed();
    error nonExistentToken();
    error signatureInvalid();
    error amountInvalid();
    error niceTry();
    error invalidInput();

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseUri,    
        address _powAddress,
        address _paymentReceiver,
        address _signer
    ) ERC1155(_baseUri) {
        name_ = _name;
        symbol_ = _symbol;

        POW = IERC20(_powAddress);
        paymentReceiver = _paymentReceiver;

        signer = _signer;
    }

    function addPod(
        uint256 _startWindow,
        uint256 _endWindow,         
        uint256 _price,
        string memory _tokenUri
    ) public onlyOwner {
        require(_startWindow < _endWindow, "open window must be before close window");

        Pod storage pod = pods[podCounter.current()];
        pod.startWindow = _startWindow;
        pod.endWindow = _endWindow;
        pod.price = _price;
        pod.tokenUri = _tokenUri;

        podCounter.increment();
    }

    function editPod(
        uint256 _tokenId,
        uint256 _startWindow,
        uint256 _endWindow,         
        uint256 _price,
        string calldata _tokenUri
    ) external onlyOwner {
        require(_startWindow < _endWindow, "open window must be before close window");

        pods[_tokenId].startWindow = _startWindow;
        pods[_tokenId].endWindow = _endWindow;
        pods[_tokenId].price = _price;
        pods[_tokenId].tokenUri = _tokenUri;
    }    

    /**
     * @notice Mints the given amount to receiver address
     *
     * @param _signature signature issued by PV
     * @param _validTokenIds token ids wallet is eligible to mint
     * @param _tokenIds token ids wallet wants to mint
     * @param _amounts amounts wallet wants to mint
     * @param _tokenIds amounts wallet is eligible to mint
     */
    function batchMint(
        bytes calldata _signature,        
        uint256[] calldata _validTokenIds, 
        uint256[] calldata _tokenIds,               
        uint256[] calldata _amounts,
        uint256[] calldata _maxAmounts
    ) external {

        if( _tokenIds.length != _amounts.length) {
        	revert invalidInput();
        }

        bytes32 hash = keccak256(
            abi.encodePacked(msg.sender, _validTokenIds, _maxAmounts)
        );
        if (hash.toEthSignedMessageHash().recover(_signature) != signer) {
            revert signatureInvalid();
        }

        uint256 totalPrice;

        for(uint256 i=0; i<_tokenIds.length;) {

	        if (block.timestamp < pods[_tokenIds[i]].startWindow || block.timestamp > pods[_tokenIds[i]].endWindow) {
	            revert windowClosed();
	        }
	        uint256 index = validateTokenId(_validTokenIds, _tokenIds[i]);

	        if(_amounts[i] < 1 || pods[_tokenIds[i]].amountMinted[msg.sender] + _amounts[i] > _maxAmounts[index]) {
	            revert amountInvalid();
	        }
	        pods[_tokenIds[i]].amountMinted[msg.sender] += _amounts[i];

	        totalPrice += pods[_tokenIds[i]].price * _amounts[i];

	        unchecked {
	            i++;
	        }  
        }          

        if(totalPrice > 0) {
            POW.transferFrom(msg.sender, paymentReceiver, totalPrice);
        }

        _mintBatch(msg.sender, _tokenIds, _amounts, "");
    }  

	function validateTokenId(uint256[] calldata validIds, uint256 num) internal pure returns (uint256) {
	    for (uint256 i = 0; i < validIds.length;) {
	        if (validIds[i] == num) {
	            return i;
	        }

	        unchecked {
	            i++;
	        }  
	    }
	    revert niceTry();
	}


    /**
     * @notice Mints the given amount to receiver address
     *
     * @param _receiver the receiving wallet
     * @param _tokenId the token id to mint
     * @param _amount the amount of tokens to mint
     */
    function ownerMint(
        address _receiver,
        uint256 _tokenId,
        uint256 _amount
    ) external onlyOwner {
        _mint(_receiver, _tokenId, _amount, "");
    }

    /**
     * @notice Mints the given s to receiver addresses
     *
     * @param _receivers the receiving wallet
     * @param _tokenId the token id to mint
     * @param _amounts the amount of tokens to mint
     */
    function ownerMintMany(
        address[] calldata _receivers,
        uint256 _tokenId,
        uint256[] calldata _amounts
    ) external onlyOwner {
        for (uint256 i; i < _receivers.length; ) {
            _mint(_receivers[i], _tokenId, _amounts[i], "");

            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Edit metadata base URI
     *
     * @param _baseURI the new base URI
     *
     */
    function setBaseURI(
        string memory _baseURI
    ) external onlyOwner {
        _setURI(_baseURI);
    }

    /**
     * @notice Edit the address to receives POW payments
     *
     * @param _paymentReceiver the new receiving address
     *
     */
    function setPaymentReceiver(
        address _paymentReceiver
    ) external onlyOwner {
        paymentReceiver = _paymentReceiver;
    }

    /**
     * @notice Change the wallet address required to sign tickets
     *
     * @param _signer the new signing address
     *
     */
    function setSigner(
        address _signer
    ) external onlyOwner {
        signer = _signer;
    }

    function amountMinted(uint256 _tokenId, address _account) public view returns (uint256) {
        return pods[_tokenId].amountMinted[_account];
    }

    /**
     * @notice returns the metadata uri for a given id
     *
     * @param _id the card id to return metadata for
     */
    function uri(
        uint256 _id
    ) public view override returns (string memory) {
        if (!exists(_id)) revert nonExistentToken();

        return string(abi.encodePacked(super.uri(_id), pods[_id].tokenUri));
    }
}