// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./BaseERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


//////////////////////////////////////////////
//                                          //
//   _          _       ____    _    ___    //
//  | |    __ _| |_ ___|  _ \  / \  / _ \   //
//  | |   / _` | __/ _ \ | | |/ _ \| | | |  //
//  | |__| (_| | ||  __/ |_| / ___ \ |_| |  //
//  |_____\__,_|\__\___|____/_/   \_\___/   //
//                                          //
//////////////////////////////////////////////


contract LateDAO is BaseERC721A {
    using SafeMath for uint256;
    using ECDSA for bytes32;

    ProjectState public state;

    uint256 public constant MAX_SUPPLY = 10000;

    uint256 public price = 0.26 ether;
    bool private _bypassSignatureChecking = false;
    string private _baseTokenURI;

    mapping(bytes => uint256) private _ticketUsed;
    mapping(ProjectState => uint256) private _mintLimit;

    address public signerAddress;
    address private _wallet = 0x6DEA85F7Bb8216e327A275e3eC54CCf0885bccD4;
    

    enum ProjectState {
        Prepare, //0
        WhitelistSale, //1
        PublicSale, //2
        Finished //3
    }

    constructor(string memory _tokenURI) ERC721A("LateDAO", "LATE", 4) {
        _baseTokenURI = _tokenURI;
        state = ProjectState.Prepare;
        signerAddress = 0x534C0c297A123bb09Fa6f5B341F74eB931aCe0f3;
        _mintLimit[ProjectState.WhitelistSale] = 10;
        _mintLimit[ProjectState.PublicSale] = 10;
    }

    ////// External Modifying Functions //////

    // update token URI
    function updateMyTokenURI888(string memory tokenURI) external onlyOwner {
        _baseTokenURI = tokenURI;
    }

    // update project state
    function updateProjectState(ProjectState _newState) external onlyOwner {
        state = _newState;
    }

    // emergency bypass signature checking
    function updateBypassSignatureChecking(bool _status) external onlyOwner {
        _bypassSignatureChecking = _status;
    }

    // update signer address
    function updateSignerAddress(address _address) external onlyOwner {
        signerAddress = _address;
    }

    // update wallet address
    function updateWalletAddress(address _address)
        external
        onlyOwner
    {
        _wallet = _address;
    }

    // update price
    function updatePrice(uint256 _newPrice)
        external
        onlyOwner
    {
        require(
            _newPrice >= 0.01 ether,
            "Price too low"
        );

        require(
            _newPrice < 5 ether,
            "Price too high"
        );

        price = _newPrice;
    }

    // airdrop NFT
    function airdropNFTFixed(address[] calldata _address, uint256 num)
        external
        onlyOwner
    {
        require(
            (_address.length * num) <= 1000,
            "Maximum 1000 tokens per transaction"
        );

        require(
            totalSupply() + (_address.length * num) <= MAX_SUPPLY,
            "Exceeds maximum supply"
        );

        for (uint256 i = 0; i < _address.length; i++) {
            _baseMint(_address[i], num);
        }
    }

    // airdrop NFT
    function airdropNFTDynamic(address[] calldata _address, uint256[] calldata _nums)
        external
        onlyOwner
    {
        
        uint256 sum = 0;
        for (uint i = 0; i < _nums.length; i++) {
            sum = sum + _nums[i];
        }
        
        require(
            sum  <= 1000,
            "Maximum 1000 tokens per transaction"
        );

        require(
            totalSupply() + sum <= MAX_SUPPLY,
            "Exceeds maximum supply"
        );

        for (uint256 i = 0; i < _address.length; i++) {
            _baseMint(_address[i], _nums[i]);
        }
    }

    // mint multiple token
    function mintMyNFT666(
        uint256 _num,
        bytes memory _ticket,
        bytes memory _signature
    ) public payable {

        // check if sale is stared 
        require(
            (ProjectState.Prepare != state && ProjectState.Finished != state),
            "Sale is not started"
        );

        // only EOA can call this function
        require(msg.sender == tx.origin, "Only EOA can call this function");


        // minting amt cannot be over the limit of the current state
        require(
            (_num > 0 && _num <= _mintLimit[state]),
            "Incorrect minting amount"
        );

        // each ticket cannot be used to mint over the allowed amt 
        if (!_bypassSignatureChecking) {
            require(_ticketUsed[_ticket] + _num <= _mintLimit[state] , "Minting amount exceed limit");
        }

        // validate ticket
        if (!_bypassSignatureChecking) {
            require(
                isSignedBySigner(
                    msg.sender,
                    _ticket,
                    _signature,
                    signerAddress
                ),
                "Ticket is invalid"
            );
        }

        _ticketUsed[_ticket] +=  _num;

        _mint(_num);
 
    }

    // withdraw the balance if needed
    function withdraw() external onlyOwner {
        payable(_wallet).transfer(  address(this).balance );
    }

    ////// Internal Functions //////

    function _mint(uint256 num) private {
        require(totalSupply() + num <= MAX_SUPPLY, "Exceeds maximum supply");
        require(msg.value >= (price * num), "Not enough ETH was sent");

        // transfer the fund to the project team
        payable(_wallet).transfer(msg.value);
        _baseMint(num);
    }

    /////// Readonly and Pure Functions //////

    // required override
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // return the wallet address by index
    function walletAddress() external view returns (address) {
        return _wallet;
    }

    // validate signature address
    function isSignedBySigner(
        address _sender,
        bytes memory _ticket,
        bytes memory _signature,
        address signer
    ) private pure returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(_sender, _ticket));
        return signer == hash.recover(_signature);
    }
}