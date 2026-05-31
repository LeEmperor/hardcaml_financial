# Feedparser

Should take in some wire format, and then parse apart the messages to build some sort of internal state.

Biggest thing is fixed/variable length field parsing, which requires the use of barrel shifters, which unfortunatley are just gigantic muxes and don't play well with timing.

First one to be built shall tarket the CME, which uses the SBE protocol.

SBE (Simple Binary Encoding)
    Binary
    Fixed-width



# Major Components
1. Network Front-end
    Ethernet MAC of some sort

    Most likely will just connect via ethernet

    For testing purposes, may require UART usage since I have no eth cable for a little bit.

2. Packet Framer
    
    reconstruct messages from UDP payload stream
        needs a sequence gap detector
        and some sort of handler for multicast groups of UDP

3. Message Dispatch
    read message type (a specific byte)
    route the data to the corresponding field extractor based on this type
    known offset = known width, quite nice

4. Field Extractor
    giant wire slicer

      Add Order message (ITCH 5.0):
        offset 0:  message_type     [1 byte]
        offset 1:  stock_locate     [2 bytes, big-endian]
        offset 3:  tracking_number  [2 bytes]
        offset 5:  timestamp        [6 bytes, nanoseconds]
        offset 11: order_ref        [8 bytes]
        offset 19: buy_sell         [1 byte]
        offset 20: shares           [4 bytes]
        offset 24: stock            [8 bytes, ASCII padded]
        offset 32: price            [4 bytes, fixed-point]

5. Symbol Filter / Lookup
     filter out symbols we don't care about at the RTL level
    A TCAM or hash table in BRAM maps the 8-byte stock ticker to an internal symbol ID

6. Order Book Update Engine

    Downstream of the parser; usually pipelined directly
    Maintains price levels in on-chip BRAM (sorted structures, often sorted linked lists or price arrays)
    Add / Cancel / Replace / Execute messages each trigger specific BRAM ops
