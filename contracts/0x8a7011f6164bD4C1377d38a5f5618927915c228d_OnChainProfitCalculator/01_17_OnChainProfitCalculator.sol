// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "erc721a/contracts/ERC721A.sol";
import "./GenZeroProfitCalculator.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

/// @title This NFT is linked to its proper floor price, totally on chain.
/// @author anon

contract OnChainProfitCalculator is ERC721A, ReentrancyGuard, Ownable, DefaultOperatorFilterer, GenZeroProfitCalculator{
    uint256 public COLLECTION_SIZE=1000;
    /// @dev Profit calculation
    mapping(address => uint256) internal gasCost;
    mapping(address => uint256) internal numberSales;
    mapping(address => uint256) internal profits;
    mapping(address => uint256) internal cost;
    address internal lastFrom;
    address internal lastTo;
    address internal opensea = 0x1E0049783F008A0085193E00003D00cd54003c71; // opensea approval
    address internal openseaSale = 0x00000000006c3852cbEf3e08E8dF289169EdE581; // opensea money distributor. Yet another great invention of two contract addresses. 
    mapping(uint256 => address[]) public wallets;
    uint256 public lastSalePrice;
    
    /// @dev art.
    mapping(uint256 => address) public genArtAddress;
    mapping(uint256 => uint256) public genArtChoice;
    mapping(uint256 => uint256) public genArtCount;
    mapping(uint256 => uint256) public genArtLimit;
    mapping(uint256 => uint256) public genArtPrice;
    mapping(uint256 => address) public genArtPayoutAddress;

    /// @dev modifiers
    modifier onlyHolder(uint256 tokenId) {
        require(msg.sender == ownerOf(tokenId), "You need to be the holder of this NFT");
        _;
    }

  constructor() ERC721A("OnChainProfitCalculator", "OCPC") {
      genArtPrice[0] = 0.0069 ether;
      genArtAddress[0] = address(this);
      genArtLimit[0] = 10 ** 18;
      // 20 for team reserve.
      _safeMint(msg.sender, 20);
  }

  /// @notice Mint process.
  function mint() external{
      // Free mint, 1 mints per tx, total supply 1000.
      require(totalSupply() + 1 <= COLLECTION_SIZE, "Reached max supply");
      require(_numberMinted(msg.sender) < 1, "Max mint: 1");
      _safeMint(msg.sender, 1);
      gasCost[msg.sender] += tx.gasprice * 99929;
  }

  /// @notice Strings useful for properties and drawing.
  function stringETHint(int256 val) internal pure returns (string memory){
      string memory sign = val < 0 ? "-" : "";
      val = val < 0 ? -val : val;
      uint256 ent = uint256(val) / 10 ** 18;
      uint256 dec = (uint256(val) - 10 ** 18 * ent) / 10 ** 15;
      if (ent > 0 || dec > 0){
          return string(abi.encodePacked(
              sign,
              Strings.toString(ent),
              ".",
              dec < 100 ? "0" : "",
              dec < 10 ? "0" : "",
              Strings.toString(dec)
          )
                       );
      }
      else{
          return "0";
      }
  }

  function stringETHuint(uint256 val) internal pure returns (string memory){
      uint256 ent = uint256(val) / 10 ** 18;
      uint256 dec = (uint256(val) - 10 ** 18 * ent) / 10 ** 15;
      if (ent > 0 || dec > 0){
          return string(abi.encodePacked(
              Strings.toString(ent),
              ".",
              dec < 100 ? "0" : "",
              dec < 10 ? "0" : "",
              Strings.toString(dec)
          )
                       );
      }
      else{
          return "0";
      }
  }

  /// @notice Set wallet addresses if multiple.
  function setWallets(
      address[] calldata addresses,
      uint256 tokenId
  ) external onlyHolder(tokenId){
      wallets[tokenId] = addresses;
  }


  /// @notice Get profit profile from tokenId.
  function getProfitCalculator(uint256 tokenId) public view returns (ProfitCalculator memory){
      address[] memory _wallets;
      if (wallets[tokenId].length > 0){
          _wallets = wallets[tokenId];
      }
      else{
          _wallets = new address[](1);
          _wallets[0] = ownerOf(tokenId);
      }
      ProfitCalculator memory pc;
      pc.tokenId = tokenId;
      pc.holder = Strings.toHexString(uint160(ownerOf(tokenId)), 20);
      for(uint i=0; i<_wallets.length; i++){
          pc.totalNumberSales += numberSales[_wallets[i]];
          pc.totalBalance += balanceOf(_wallets[i]);
          pc.totalGasCost += gasCost[_wallets[i]];
          pc.totalCost += cost[_wallets[i]];
          pc.totalProfit += profits[_wallets[i]];
      }
      pc.totalCost += pc.totalGasCost;
      pc.potentialTotalProfit = int(pc.totalProfit) + int(lastSalePrice * pc.totalBalance * 875 / 1000) - int(pc.totalCost);

      pc.numberBought = Strings.toString(pc.totalNumberSales + pc.totalBalance);
      pc.numberRemaining = Strings.toString(pc.totalBalance);
      pc.realizedProfit = stringETHint(int(pc.totalProfit) - int(pc.totalCost));
      pc.unrealizedProfit = stringETHint(int(lastSalePrice * pc.totalBalance * 875 / 1000));
      pc.stringPotentialTotalProfit = stringETHint(pc.potentialTotalProfit);
      pc.stringTotalCost = stringETHuint(pc.totalCost);
      if (pc.totalCost == 0){
          pc.returnRate = "0";
      }
      else{
          pc.returnRate = stringETHint((int(pc.potentialTotalProfit) * 10 ** 20 / int(pc.totalCost)));
      }
      return pc;
  }
  
  /// @notice NFT metadata.
  function property(ProfitCalculator memory pc) internal view returns (string memory){
      string memory _property = "";
      _property = string(abi.encodePacked(
          '{"display_type": "number", "trait_type":"Number Bought","value":', pc.numberBought, '},',
          '{"display_type": "number", "trait_type":"Number Remaining","value":', pc.numberRemaining, '},'
      )
                        );
      _property = string(abi.encodePacked(
          _property, '{"display_type": "number", "trait_type":"Realized Profit","value":', pc.realizedProfit, '},',
          '{"display_type": "number", "trait_type":"Unrealized Profit","value":', pc.unrealizedProfit, '},'
      )
                        );
      _property = string(abi.encodePacked(
          _property, '{"display_type": "number", "trait_type":"Potential Total Profit","value":', pc.stringPotentialTotalProfit, '},',
          '{"display_type": "number", "trait_type":"Total Cost","value":', pc.stringTotalCost, '},'
      )
                        );
      _property = string(abi.encodePacked(
          _property, '{"display_type": "number", "trait_type":"Return Rate","value":', pc.returnRate, '},',
          '{"display_type": "number", "trait_type":"Art Type","value":', Strings.toString(genArtChoice[pc.tokenId]), '}'
      )
                        );
      return _property;
  }

    
  /// @notice Next generation art generated from profit profile.
  function setGenArtAddressArtist(uint256 generation, address _address, uint256 _limit, uint256 _price, address payoutAddress) external{
      require(genArtAddress[generation] == address(0), "This generation was set by others");
      genArtAddress[generation] = _address;
      genArtLimit[generation] = _limit;
      genArtPrice[generation] = _price;
      genArtPayoutAddress[generation] = payoutAddress;
  }

  function getGenArtAddress(uint256 tokenId) internal view returns (address){
      return genArtAddress[genArtChoice[tokenId]];
  }

  function setGenArtAddressHolder(uint256 tokenId, uint256 generation) external payable onlyHolder(tokenId){
      require(genArtAddress[generation] != address(0), "Not drawn yet");
      require(msg.value >= genArtPrice[generation], "Not sufficient funds");
      require(genArtCount[generation] < genArtLimit[generation], "Limit reached!");
      genArtChoice[tokenId] = generation;
      genArtCount[generation]++;
      (bool success, ) = genArtPayoutAddress[generation].call{value: msg.value}(""); // Pay to the author.
      require(success, "Transfer failed.");
  }

  function tryDifferentGeneration(uint256 tokenId, uint256 generation) public view returns (string memory){
      string memory _name = string(abi.encodePacked("Profit Calculator #", Strings.toString(tokenId)));
      string memory _description = "A NFT collection which calculate your profits on its own. The first onchain NFT which tracks its own floor price.";
      ProfitCalculator memory pc = getProfitCalculator(tokenId);
      string memory _properties = property(pc);
      string memory _image = ProfitCalculatorDrawingContract(genArtAddress[generation]).image(pc);
      return string(
          abi.encodePacked(
              "data:application/json;base64,",
              Base64.encode(
                  bytes(
                      abi.encodePacked(
                          '{"name":"', _name,
                          '", "description": "', _description,
                          '", "attributes": [', _properties,
                          '], "image":"', _image, '"',
                          '}'
                      )
                  )
              )
          )
      );
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory){
      string memory _name = string(abi.encodePacked("Profit Calculator #", Strings.toString(tokenId)));
      string memory _description = "A NFT collection which calculate your profits on its own. The first onchain NFT which tracks its own floor price.";
      ProfitCalculator memory pc = getProfitCalculator(tokenId);
      string memory _properties = property(pc);
      string memory _image = ProfitCalculatorDrawingContract(getGenArtAddress(tokenId)).image(pc);
      return string(
          abi.encodePacked(
              "data:application/json;base64,",
              Base64.encode(
                  bytes(
                      abi.encodePacked(
                          '{"name":"', _name,
                          '", "description": "', _description,
                          '", "attributes": [', _properties,
                          '], "image":"', _image, '"',
                          '}'
                      )
                  )
              )
          )
      );
  }

  function setOpensea(address operator) external onlyOwner{
      opensea = operator;
      // Just in case opensea changes their contract again.
  }
  function setOpenseaSale(address operator) external onlyOwner{
      openseaSale = operator;
  }

  function isApprovedForAll(address owner, address operator) public view override returns (bool) {
      return (opensea == operator);
  }

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
      require(operator == opensea, "This is only tradable on opensea");
      super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
      require(operator == opensea, "This is only tradable on opensea");
      super.approve(operator, tokenId);
  }
  /// @notice Add gas calculation
  function transferFrom(
      address from,
      address to,
      uint256 tokenId
  ) public override onlyAllowedOperator(from){
      require(tokenId != 0, "Token ID 0 is for advertisement usage!");
      if (msg.sender == from){
          gasCost[from] += tx.gasprice * 49815;
      }
      else{ // sales on secondary.
          numberSales[from] += 1;
          // Handling the last sale. Otherwise receive() will lead to execution reverted error on opensea.
          lastFrom = from;
          lastTo = to;
          gasCost[lastTo] += tx.gasprice * 260000;
      }
      super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
      super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
      public
      override
      onlyAllowedOperator(from)
  {
      super.safeTransferFrom(from, to, tokenId, data);
  }

  /// @notice Secondary sales fee
  /// @dev We use last sale price as our floor approximation. This is legit since we don't have rarities. However, there are methods so that rarities won't be an issue.
  receive() external payable{
      // 10% royalty
      if (msg.sender == openseaSale){ 
          lastSalePrice = msg.value * 10;
          cost[lastTo] += lastSalePrice;
          profits[lastFrom] += lastSalePrice * 875 / 1000; // I gave up calculating royalties per market Place. It worked with my proper implementation of transferFrom/isApprovedForAll but fuck you opensea.
          /* Fun fact: 
             With Opensea contract, (dated 2023/01/04)
             sales = transferFrom then send ETH
             Bulk sales = send ETH then transferFrom
             /// @dev status is used to keep track of only sales. More can be done but more gas is needed, too. 
             (keeping track of the number of NFT transfered in the same tx is not easy. You don't know when is the end and thus more gas to store useless variables.)...
             /// @dev You are welcome to repeat the last 3 words in line 306.
          */
      }
  }

  /// @notice Withdraw functions
  function withdraw() external onlyOwner {
      (bool success, ) = msg.sender.call{value: address(this).balance}("");
      require(success, "Transfer failed.");
  }
  function withdrawERC20(address currency, uint256 quantity) external onlyOwner{
      ERC20(currency).transfer(msg.sender, quantity);
  }
}