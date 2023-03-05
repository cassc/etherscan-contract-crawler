// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC1155} from "lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {Pausable} from "lib/openzeppelin-contracts/contracts/security/Pausable.sol";
import {DefaultOperatorFilterer} from "lib/operator-filter-registry/src/DefaultOperatorFilterer.sol";
import {MerkleProof} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import {Strings} from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
    @title GFCEcosystem
    @dev ERC1155 contract for GFC Ecosystem
    @author curion.eth (twitter: @curi0n, site: curion.io)
    @notice Mints pass IDs 1-N where 1 is the standard origin pass, 2 is the champion origin pass, etc.
            This way, all GFC NFTs can be displayed within a single collection on marketplaces.
 */



contract GFCEcosystem is ERC1155, Ownable, Pausable, DefaultOperatorFilterer {
    //================================================================
    // Setup
    //================================================================
    
    using Strings for uint256;

    string public constant name = "Global Fit Club Ecosystem";
    string public constant symbol = "GFCE";

    address public paymentSplitterAddress;
    address[] public paperAddresses = [ //these are mainnet addresses
        0xf3DB642663231887E2Ff3501da6E3247D8634A6D, 
        0x5e01a33C75931aD0A91A12Ee016Be8D61b24ADEB, 
        0x9E733848061e4966c4a920d5b99a123459670aEe
    ];

    bool public revealed;

    struct IDParams {
        uint16 totalSupply;
        uint16 totalMinted;
        uint16 maxMintsPerWallet;
        uint64 publicMintPrice;
        uint64 whitelistMintPrice;
        bool publicMintIsOpen;
        bool whitelistMintIsOpen;
        bool paperMintIsOpen;
        bytes32 whitelistRoot;
        string metadataURI;
    }

    mapping(uint256 => IDParams) public PASS_ID_PARAMS;
    
    mapping(uint256 => mapping(address => uint16)) public passIdToMintedPerWallet;

    error CallerIsNotPaper();
    error CantMintZero();
    error ForwardFailed();
    error InsufficientFunds();
    error InvalidAddress();
    error InvalidMerkleOrWrongSender();
    error MathError();
    error PublicMintIsClosed();
    error PaperMintIsClosed();
    error TotalSupplyReached();
    error TotalSupplyWillBeReached();
    error WhitelistMintIsClosed();
    error WillHaveExceededWalletLimit();

    constructor() ERC1155("") {}

    //================================================================
    // Minting: Paper, Whitelist, and Public
    //================================================================

    function mintPass(address _sender, uint16 _qty, uint256 _id) 
        external 
        payable 
        whenNotPaused 
    {

        if( _qty == 0 ){ revert CantMintZero(); }
        IDParams memory THIS_PASS = PASS_ID_PARAMS[_id];
        if( THIS_PASS.totalMinted + _qty > THIS_PASS.totalSupply ){ revert TotalSupplyWillBeReached(); }
        if(_sender != owner() ) {
            if( passIdToMintedPerWallet[_id][_sender] + _qty > THIS_PASS.maxMintsPerWallet ){ revert WillHaveExceededWalletLimit(); }
            if(msg.value < _qty * THIS_PASS.publicMintPrice ){ revert InsufficientFunds(); }
            if(!THIS_PASS.publicMintIsOpen ){ revert PublicMintIsClosed(); }        
        }

        passIdToMintedPerWallet[_id][_sender] += _qty;
        PASS_ID_PARAMS[_id].totalMinted += _qty;
        _mint(_sender, _id, _qty, "");
    }

    function mintPassFromPaper(address _sender, uint16 _qty, uint256 _id) 
        external 
        payable 
        whenNotPaused 
    {
        IDParams memory THIS_PASS = PASS_ID_PARAMS[_id];
        if( _qty == 0 ){ revert CantMintZero(); }
        if( !THIS_PASS.paperMintIsOpen){ revert PaperMintIsClosed(); }
       
        if( THIS_PASS.totalMinted + _qty > THIS_PASS.totalSupply ){ revert TotalSupplyWillBeReached(); }
        if( passIdToMintedPerWallet[_id][_sender] + _qty > THIS_PASS.maxMintsPerWallet ){ revert WillHaveExceededWalletLimit(); }   
        
        if( msg.value < THIS_PASS.whitelistMintPrice ){ revert InsufficientFunds(); }
        if( !callerIsPaper() ){ revert CallerIsNotPaper(); }

        passIdToMintedPerWallet[_id][_sender] += _qty;
        PASS_ID_PARAMS[_id].totalMinted += _qty;
        _mint(_sender, _id, _qty, "");
        
    }

    function whitelistMintPass(address _sender, bytes32[] memory _proof, bytes32 _leaf, uint16 _qty, uint256 _id) 
        external 
        payable 
        whenNotPaused 
    {

        if( _qty == 0 ){ revert CantMintZero(); }
        IDParams memory THIS_PASS = PASS_ID_PARAMS[_id];
        if( THIS_PASS.totalMinted + _qty > THIS_PASS.totalSupply ){ revert TotalSupplyWillBeReached(); }
        if(_sender != owner() ) {
            if( passIdToMintedPerWallet[_id][_sender] + _qty > THIS_PASS.maxMintsPerWallet ){ revert WillHaveExceededWalletLimit(); }        
            if( msg.value < _qty * THIS_PASS.whitelistMintPrice ){ revert InsufficientFunds(); }
            if( !THIS_PASS.whitelistMintIsOpen ){ revert WhitelistMintIsClosed(); }
        }

        if(!isValidMerkle(_proof, _leaf, _sender, _id)){ revert InvalidMerkleOrWrongSender(); }
        
        passIdToMintedPerWallet[_id][_sender] += _qty;
        PASS_ID_PARAMS[_id].totalMinted += _qty;
        _mint(_sender, _id, _qty, "");
    }

    function airdropPasses(address[] memory _recipients, uint256 _id) external onlyOwner {
        IDParams memory THIS_PASS = PASS_ID_PARAMS[_id];
        if(_recipients.length >THIS_PASS.totalSupply-THIS_PASS.totalMinted) { revert MathError(); }
        for(uint256 i = 0; i < _recipients.length; i++){
            ++passIdToMintedPerWallet[_id][_recipients[i]];
            _mint(_recipients[i], _id, 1, "");
        }
        PASS_ID_PARAMS[_id].totalMinted += uint16(_recipients.length);
    }

    function callerIsPaper() internal view returns (bool) {
        for(uint256 i = 0; i < paperAddresses.length; i++){
            if(msg.sender == paperAddresses[i]){ return true; }
        }
        return false;
    }

    function checkClaimEligibility(address _to, uint256 _quantity, uint256 _id) external view returns (string memory) {
        IDParams memory THIS_PASS = PASS_ID_PARAMS[_id];
        if ( !THIS_PASS.paperMintIsOpen ) {
            return "Sale is not live";
        } else if ( passIdToMintedPerWallet[_id][_to] + _quantity > THIS_PASS.maxMintsPerWallet ) {
            return "Max mints per wallet exceeded";
        } else if ( THIS_PASS.totalMinted + _quantity > THIS_PASS.totalSupply ){
            return "Not enough supply";
        }
        return "";
    }

    //================================================================
    // Setters
    //================================================================

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setPassIdTotalSupply(uint256 _id, uint256 _totalSupply) external onlyOwner {
        PASS_ID_PARAMS[_id].totalSupply = uint16(_totalSupply);
    }

    function setPassIdMaxMintsPerWallet(uint256 _id, uint256 _maxMintsPerWallet) external onlyOwner {
        PASS_ID_PARAMS[_id].maxMintsPerWallet = uint16(_maxMintsPerWallet);
    }

    function setPassIdPublicMintPrice(uint256 _id, uint256 _mintPrice) external onlyOwner {
        PASS_ID_PARAMS[_id].publicMintPrice = uint64(_mintPrice);
    }

    function setPassIdWhitelistMintPrice(uint256 _id, uint256 _mintPrice) external onlyOwner {
        PASS_ID_PARAMS[_id].whitelistMintPrice = uint64(_mintPrice);
    }

    function setPassIdPublicMintIsOpen(uint256 _id, bool _phaseIsOpen) external onlyOwner {
        PASS_ID_PARAMS[_id].publicMintIsOpen = _phaseIsOpen;
    }

    function setPassIdWhitelistMintIsOpen(uint256 _id, bool _phaseIsOpen) external onlyOwner {
        PASS_ID_PARAMS[_id].whitelistMintIsOpen = _phaseIsOpen;
    }

    function setPassIdPaperMintIsOpen(uint256 _id, bool _phaseIsOpen) external onlyOwner {
        PASS_ID_PARAMS[_id].paperMintIsOpen = _phaseIsOpen;
    }

    function setPaymentSplitterAddress(address _paymentSplitterAddress) external onlyOwner {
        if(_paymentSplitterAddress == address(0)){ revert InvalidAddress(); }
        paymentSplitterAddress = _paymentSplitterAddress;
    }

    function setPassIdWhitelistRoot(uint256 _id, bytes32 _whitelistRoot) external onlyOwner {
        PASS_ID_PARAMS[_id].whitelistRoot = _whitelistRoot;
    }

    function setPassIdMetadataUri(uint256 _id, string memory _metadataUri) external onlyOwner {
        PASS_ID_PARAMS[_id].metadataURI = _metadataUri;
    }

    function pushPaperAddress(address _paperAddress) external onlyOwner {
        paperAddresses.push(_paperAddress);
    }

    function replacePaperAddress(uint256 _index, address _paperAddress) external onlyOwner {
        paperAddresses[_index] = _paperAddress;
    }


    //================================================================
    // Getters
    //================================================================

    function isValidMerkle(bytes32[] memory _proof, bytes32 _leaf, address _mintingAddress, uint256 _id) private view returns (bool) {
        bytes32 checcak = keccak256(abi.encodePacked(_mintingAddress));
        if (_leaf == checcak ) {
            return MerkleProof.verify(_proof, PASS_ID_PARAMS[_id].whitelistRoot, _leaf);
        } else {
            revert InvalidMerkleOrWrongSender();
        }
    }

    /// @notice override uri to include separate URI for each ID
    function uri(uint256 _id) public view override returns (string memory) {
        return string(abi.encodePacked(PASS_ID_PARAMS[_id].metadataURI));
    }



    //=========================================================================
    // WITHDRAWALS for ERC20 and ETH
    //=========================================================================

    function withdrawERC20FromContract(address _to, address _token) external onlyOwner {
        (bool os ) = IERC20(_token).transfer(_to, IERC20(_token).balanceOf(address(this)));
        if(!os){ revert ForwardFailed(); }
    }

    function withdrawEthFromContract() external onlyOwner  {
        require(paymentSplitterAddress != address(0), "Payment splitter address not set");
        (bool os, ) = payable(paymentSplitterAddress).call{ value: address(this).balance }('');
        if(!os){ revert ForwardFailed(); }
    }

    //================================================================
    // ERC1155 Overrides
    //================================================================
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}