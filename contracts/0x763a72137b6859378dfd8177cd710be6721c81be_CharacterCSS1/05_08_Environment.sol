// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./GridHelper.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library Environment {
  uint internal constant TOTAL_BASIC_COLOURS = 5;
  uint internal constant TOTAL_EMBELLISHED_COLOURS = 6;
  uint internal constant TOTAL_DEGRADED_COLOURS = 8; // includes grey

  // LW, RW, FLOOR
  string internal constant EXECUTIVE_COLOUR_PERCENTAGES = "040020025000070000";
  string internal constant LAB_COLOUR_PERCENTAGES = "040020025000070000";
  string internal constant FACTORY_COLOUR_PERCENTAGES = "040020025000070000";

  // Darker Gray, Orange, Dark Gray, Red, Light Gray, Orange, Lightest Gray, Red
  string internal constant EXECUTIVE_DEGRADED_HSL = "120001015120001035120001061120002088019068078019032045019058048002047049";
  string internal constant LAB_DEGRADED_HSL = "120001015120001035120001061120002088156015049050047054276021058155037049";
  string internal constant FACTORY_DEGRADED_HSL = "120001015120001035120001061120002088021042074203032059319029046243031039";

  // EXECUTIVE
  // Combined without shades
  string internal constant EXECUTIVE_COLOURS_BASIC = "000000069240003029000000069240003029000000069000000069240003013000000069354100060240003013000000069240003013240003029047100050240003013240003029240003013240003029121082050240003013240003029240003013240003029221082050240003013354100060000100004000100004022100050041100050047100050021081004021081004030100013022100045221081088194090077200075078195086089200084076";
  string internal constant EXECUTIVE_COLOURS_EMBELLISHED = "121082050093090004099074009095085054099075072093090004221082050194089004199074009195085054199075080194089004339082050314089004317074009313085054318075084314089004357061040040091044040091062040091044040091062040091044137093049197100052287100053347100053047100052287100053259100052184100052083100052050100050000100050083100052093063053082084048066100048053100050036100050066100048060087053061100042070100040101055042165100025070100040";
  // Combined with shades
  string internal constant EXECUTIVE_COLOURS_BASIC_SHADE = "000000050240003029000000050240003029000000050000000050240003029000000050000086027240003029000000050240003029240003013047100032240003029240003013240003029240003013104079046240003029240003013240003029240003013204079046240003029000086027000061010000100007013091043041100045047100032022080008022081012030100015022100040204079087196071077180054080195093089195095092";
  string internal constant EXECUTIVE_COLOURS_EMBELLISHED_SHADE = "104079046096071004080054015095093054095096068096071004204079046196071004180054015195093054195096068196071004322079046316071004299054015313093054313096068316071004357078056040091062040091044040091062040091044040091062168100054257100053317100053017100052047100056317100053284100052212092052155100052068100052032100050155100052093063057093068048075100048058100050047100050075100048060100062061100044065100041081077041137055037065100041";

  // LAB
  // Combined without shades
  string internal constant LAB_COLOURS_BASIC = "185053039180055056185053039180095040181066049231095074252070052231095074210049067030100050168056095228081062168056095051093072182081087240060097253081078240060097224062081245080083352033081165032066027028078027033080037031079143014078000000100143014078237045053183099034207099060207099060040090096239066051176077048221081088194090077200075078195086089200084076";
  string internal constant LAB_COLOURS_EMBELLISHED = "158100077228081062168056095051093072182081087168056095238100086253081078240060097224062081245080083253081078190054036252070052231095074210049067030100050252070052144090033040091044040091062040091044040091062040091044287100053047100052137093049347100053197100052287100053000100050050100050083100052184100052259100052083100052036100050053100050066100048082084048093063053082084048165100025101055042070100040061100042060087053070100040";
  // Combined with shades
  string internal constant LAB_COLOURS_BASIC_SHADE = "181085042184045075181085042180059062181062052251085079251073027251085079211053076030100050182081087229047032182081087051090084180064063242083093252047060242083093224058089244079072004029080164031070021030079022034081023028075143014068183100080143014068237045048183099028239066051207099060041090092238072019176077048204079087196071077180054080195093089195095092";
  string internal constant LAB_COLOURS_EMBELLISHED_SHADE = "169048056229047032182081087051090084180064063182081087241047074252047060242083093224058089244079072252047060184021040251073027251085079211053076030100050251073027147089054040091062040091044040091062040091044040091062317100053047100056168100054017100052257100053317100053032100050068100052155100052212092052284100052155100052047100050058100050075100048093068048093063057093068048137055037081077041065100041061100044060100062065100041";

  // FACTORY
  // Combined without shades
  string internal constant FACTORY_COLOURS_BASIC = "232053033232052058232054032232051037232058059196085079193083063193048054193064047193089055231032035196085079231032035300085082000000085249069060196085079231032035300085082000000085266083081162085079197031035266083081000000085033098060196085068231032035196085068000000085300085082196085079231032035033100052000000085221081088194090077200075078195086089200084076";
  string internal constant FACTORY_COLOURS_EMBELLISHED = "160073059280078043280077074340097062160071039280078043280094041340086057280084075340084055340087027340086057162085079266083081266083081197031035000000085266083081220067026040091044040091072040091044040091072040091044197100052287100053137093049347100053047100052287100053083100052050100050000100050259100052184100052050100050082084048066100048036100050053100050093063053082084048101055042070100040165100025060087053061100042070100040";
  // Combined with shades
  string internal constant FACTORY_COLOURS_BASIC_SHADE = "232066056233054034232066067232071029232091066196084068193045040193073053193067051193070044229034024193083063229034024033098060000000052243039046193083063229034024033098060000000052359097059159084063195034025266086072000000052033098044193083052229034024193083052000000052321076067193083063229034024033098060000000052204079087196071077180054080195093089195095092";
  string internal constant FACTORY_COLOURS_EMBELLISHED_SHADE = "243039046300085082193083063229034024000000052300085082249069060033098060196085079231032035000000085033098060159084063359097059266086072195034025000000052359097059220096052040091072040091044040091072040091044220087032257100053317100053168100054017100052047100056317100053155100052068100052032100050284100052212092052068100052093068048075100048047100050058100050093063057093068048081077041065100041137055037060100062061100044065100041";

  string internal constant DEGRADED_COLOUR_PERCENTAGES = "064115153191217237251256";
  string internal constant BASIC_COLOUR_PERCENTAGES = "064115153191217237251256";
  string internal constant EMBELLISHED_COLOUR_PERCENTAGES = "064115153191217237251256";

  function increaseValueByPercentage(uint baseLightness, uint percentage) internal pure returns(uint) {
    uint value = baseLightness + (baseLightness * percentage / 100);
    if (value > 100) {
      value = 100;
    }
    return value;
  }

  function decreaseValueByPercentage(uint baseLightness, uint percentage) internal pure returns (uint) {
    return baseLightness - (baseLightness * percentage / 100);
  }

  function getColours(string memory machine, uint baseValue) external pure returns (uint[] memory) {
    uint[] memory colourArray = new uint[](36); // 6 colours, 3*2 values each

    uint colourIndex = getColourIndex(baseValue);

    if (colourIndex < 8) { // degraded
      colourArray = getDegradedShell(colourArray, machine, baseValue);
    } else { // basic or embellished
      colourArray = getBasicEmbelishedShell(colourArray, machine, baseValue);
    }
    return colourArray;
  }

  function getColourIndex(uint baseValue) internal pure returns(uint) {
    uint[] memory colourProbabilitiesArray = GridHelper.createEqualProbabilityArray(24);

    uint index = 100;
    for (uint i = 0; i < colourProbabilitiesArray.length; ++i) {
      if (baseValue < colourProbabilitiesArray[i]) {
        index = i;
        break;
      }
    }
    if (index == 100) {
      index = 23;
    }

    return index;
  }

  function selectBasicEmbellishedPalette(string memory machine, uint baseValue) internal pure returns (string[] memory) {
    string[] memory basicPalette = new string[](2);
    uint index = getColourIndex(baseValue);

    uint state = 2;
    if (index < 16) {
      state = 1;
    }

    index = index % 8;

    uint size;
    if (state == 1) {
      size = TOTAL_BASIC_COLOURS * 9;
    } else {
      size = TOTAL_EMBELLISHED_COLOURS * 9;
    }

    // could be simplified by storing every colour in a single string but this is more readable and easier to change
    if (keccak256(bytes(machine)) == keccak256(bytes("Altar"))) { // executive
      if (state == 1) {
        basicPalette[0] = string(GridHelper.slice(bytes(EXECUTIVE_COLOURS_BASIC), index * size, size));
        basicPalette[1] = string(GridHelper.slice(bytes(EXECUTIVE_COLOURS_BASIC_SHADE), index * size, size));
      } else {
        basicPalette[0] = string(GridHelper.slice(bytes(EXECUTIVE_COLOURS_EMBELLISHED), index * size, size));
        basicPalette[1] = string(GridHelper.slice(bytes(EXECUTIVE_COLOURS_EMBELLISHED_SHADE), index * size, size));
      }
    } else if (keccak256(bytes(machine)) == keccak256(bytes("Apparatus")) || keccak256(bytes(machine)) == keccak256(bytes("Cells"))) { // lab
      if (state == 1) {
        basicPalette[0] = string(GridHelper.slice(bytes(LAB_COLOURS_BASIC), index * size, size));
        basicPalette[1] = string(GridHelper.slice(bytes(LAB_COLOURS_BASIC_SHADE), index * size, size));
      } else {
        basicPalette[0] = string(GridHelper.slice(bytes(LAB_COLOURS_EMBELLISHED), index * size, size));
        basicPalette[1] = string(GridHelper.slice(bytes(LAB_COLOURS_EMBELLISHED_SHADE), index * size, size));
      }
    } else { // factory
      if (state == 1) {
        basicPalette[0] = string(GridHelper.slice(bytes(FACTORY_COLOURS_BASIC), index * size, size));
        basicPalette[1] = string(GridHelper.slice(bytes(FACTORY_COLOURS_BASIC_SHADE), index * size, size));
      } else {
        basicPalette[0] = string(GridHelper.slice(bytes(FACTORY_COLOURS_EMBELLISHED), index * size, size));
        basicPalette[1] = string(GridHelper.slice(bytes(FACTORY_COLOURS_EMBELLISHED_SHADE), index * size, size));
      }
    }

    return basicPalette;
  }

  function getDegradedShell(uint[] memory colourArray, string memory machine, uint baseValue) internal pure returns (uint[] memory) {

    string memory degradedHsl;
    string memory degradedPercentages;

    if (keccak256(bytes(machine)) == keccak256(bytes("Altar"))) { // executive
      degradedHsl = EXECUTIVE_DEGRADED_HSL;
      degradedPercentages = EXECUTIVE_COLOUR_PERCENTAGES;
    } else if (keccak256(bytes(machine)) == keccak256(bytes("Apparatus")) || keccak256(bytes(machine)) == keccak256(bytes("Cells"))) { // lab
      degradedHsl = LAB_DEGRADED_HSL;
      degradedPercentages = LAB_COLOUR_PERCENTAGES;
    } else { // factory
      degradedHsl = FACTORY_DEGRADED_HSL;
      degradedPercentages = FACTORY_COLOUR_PERCENTAGES;
    }

    uint index = getColourIndex(baseValue);
    uint[] memory singleColour = new uint[](3); // h, s, l
    for (uint i = 0; i < 3; ++i) {
      singleColour[i] = GridHelper.stringToUint(string(GridHelper.slice(bytes(degradedHsl), (index)*9 + 3*i, 3))); // 9 = h,s,l to 3 significant digits
    }
    uint[] memory colourPercentages = GridHelper.setUintArrayFromString(degradedPercentages, 6, 3);
    
    for (uint i = 0; i < 12; ++i) { // 12 = 6 colours, 2 values each
      colourArray[i*3] = singleColour[0];
      colourArray[i*3+1] = singleColour[1];
      colourArray[i*3+2] = increaseValueByPercentage(singleColour[2], colourPercentages[i%6]);
    }

    return colourArray;
  }

  function getBasicEmbelishedShell(uint[] memory colourArray, string memory machine, uint baseValue) internal pure returns (uint[] memory) {

    uint index = getColourIndex(baseValue);

    uint state = 2;
    if (index < 16) {
      state = 1;
    }

    uint numColours;
    if (state == 1) {
      numColours = TOTAL_BASIC_COLOURS;
    } else {
      numColours = TOTAL_EMBELLISHED_COLOURS;
    }

    string[] memory colourAvailableStrings = selectBasicEmbellishedPalette(machine, baseValue);
    uint[] memory coloursAvailable = GridHelper.setUintArrayFromString(colourAvailableStrings[0], numColours*3, 3);
    uint[] memory coloursAvailableShade = GridHelper.setUintArrayFromString(colourAvailableStrings[1], numColours*3, 3);

    for (uint i = 0; i < 6; ++i) {
      for (uint j = 0; j < 3; ++j) { // j = h, s, l
        // Duplicate colours for linear gradient
        colourArray[2*i*3+j] = coloursAvailable[3*(i % numColours) + j];
        colourArray[(2*i+1)*3+j] = coloursAvailableShade[3*(i % numColours) + j];
      }
    }

    return colourArray;
  }

}