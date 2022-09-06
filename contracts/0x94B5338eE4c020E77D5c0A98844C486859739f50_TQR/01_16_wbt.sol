// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;
import "@api3/airnode-protocol/contracts/rrp/requesters/RrpRequesterV0.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TQR is ERC721, RrpRequesterV0, Ownable {

    struct GT {
        bool GW;
        uint256 GWDF;
	uint256 FPU;
	uint256 PPU;
	uint256 UIN;
	uint256 gtdrawn;
	uint256 gtexpiry;
	bool paidmint;
    }

    GT[] public gti;

    address public airnode;
    bytes32 public endpointIdUint256;
    address public sponsorWallet;
    uint256 fpu;
    uint256 ppu;
    uint256 paidMintPrice;
    address mainContract;
    bool ispaid;
    bool isfree;
    bool mintingEnabled;

    mapping(address => bool) GTMintedF;
    mapping(uint256 => bool) GTUsed;

    mapping(bytes32 => bool) public expectingRequestWithIdToBeFulfilled;
    mapping(bytes32 => address) requestToSender;
    mapping(bytes32 => uint256) requestToTokenId;

    constructor(address _airnodeRrp) RrpRequesterV0(_airnodeRrp) ERC721("TQR", "TQR") {}

    function setRequestParameters(
        address _airnode,
        bytes32 _endpointIdUint256,
        address _sponsorWallet
    ) external onlyOwner() {
        airnode = _airnode;
        endpointIdUint256 = _endpointIdUint256;
        sponsorWallet = _sponsorWallet;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        if (from != address(0)) {
            address owner = ownerOf(tokenId);
            require(owner == msg.sender, "Only the owner of the NFT can transfer or burn it");
        }
    }

    function alreadyMintedFree() external view returns (bool) {
      return GTMintedF[msg.sender];
    }

    function alreadyUsed(uint256 _tokenId) external view returns (bool) {
      return GTUsed[_tokenId];
    }

    function useGT(address gtminter, uint256 _tokenId) public returns (bool) {
      require(msg.sender == mainContract, "Only the main contract may consume the GT");
      require(ownerOf(_tokenId) == gtminter, "Only the owner of this token may use it");

      GTUsed[_tokenId] = true;
      return true;
    }

    function setMintEnabled(bool _mintingEnabled) external onlyOwner() {
      mintingEnabled = _mintingEnabled;
    }

    function setPaidMintPrice(uint256 _paidMintPrice) external onlyOwner() {
      paidMintPrice = _paidMintPrice;
    }

    function setMainContract(address _mainContract) external onlyOwner() {
      mainContract = _mainContract;
    }

    function m() payable public returns (bytes32) {
	require(mintingEnabled, "Minting is not currently enabled.");


        bytes32 requestId = airnodeRrp.makeFullRequest(
                airnode,
                endpointIdUint256,
                address(this),
                sponsorWallet,
                address(this),
                this.fulfillRandomness.selector,
                ""
        );

        expectingRequestWithIdToBeFulfilled[requestId] = true;
        requestToSender[requestId] = msg.sender;
        GTMintedF[msg.sender] = isfree;
        return requestId;
    }

    function fulfillRandomness(bytes32 requestId, bytes calldata data) public {
        require(expectingRequestWithIdToBeFulfilled[requestId], "Request ID not known");

        expectingRequestWithIdToBeFulfilled[requestId] = false;
        uint256 qrngUint256 = abi.decode(data, (uint256));

        uint256 newId = gti.length;
        uint256 gwdfi = (qrngUint256 % 100);
	uint256 _gtdrawn = block.timestamp;
	uint256 _gtexpiry = _gtdrawn + 15 days;
	bool gaw = false;

	if (ispaid && gwdfi <= ppu) {
	  gaw = true;
	} else if (!ispaid && gwdfi <= fpu) {
          gaw = true;
	} else {
          gaw = false;
    	}

        gti.push(
            GT(
	      gaw,
	      gwdfi,
	      fpu,
	      ppu,
	      qrngUint256,
	      _gtdrawn,
	      _gtexpiry,
	      ispaid
            )
        );
        _safeMint(requestToSender[requestId], newId);
    }

}