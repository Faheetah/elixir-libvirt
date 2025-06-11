defmodule Libvirt.RPC.CallParserTest do
  use ExUnit.Case, async: true
  alias Libvirt.RPC.CallParser

  @proc """
  /*----- Protocol. -----*/

  /* Define the program number, protocol version and procedure numbers here. */
  const REMOTE_PROGRAM = 0x20008086;
  const REMOTE_PROTOCOL_VERSION = 1;

  enum remote_procedure {
      /* Each function must be preceded by a comment providing one or
      * more annotations:
      */

    /**
     * @generate: none
     * @priority: high
     * @acl: connect:getattr
     */
    REMOTE_PROC_CONNECT_OPEN = 1,

    /**
     * @generate: none
     * @priority: high
     * @acl: none
     */
    REMOTE_PROC_CONNECT_CLOSE = 2

  };
  """

  describe "procedure" do
    test "multiple procs" do
      {:ok, parsed, _, _, _, _} = CallParser.parse(@proc)
      procedures = Enum.filter(parsed, fn {type, _val} -> type == :procedure end)

      assert procedures ==
               [
                 procedure: ["REMOTE_PROC_CONNECT_OPEN", 1],
                 procedure: ["REMOTE_PROC_CONNECT_CLOSE", 2]
               ]
    end

    test "procedure with readstream" do
      code = """
      enum remote_procedure {
        /**
        * @generate: both
        * @readstream: 1
        * @sparseflag: VIR_STORAGE_VOL_DOWNLOAD_SPARSE_STREAM
        * @acl: storage_vol:data_read
        */
        REMOTE_PROC_STORAGE_VOL_DOWNLOAD = 209,
      }
      """

      {:ok, parsed, _, _, _, _} = CallParser.parse(code)
      assert parsed == [{:procedure, ["readstream", "REMOTE_PROC_STORAGE_VOL_DOWNLOAD", 209]}]
    end

    test "procedure with writestream" do
      code = """
      enum remote_procedure {
        /**
        * @generate: both
        * @writestream: 1
        * @sparseflag: VIR_STORAGE_VOL_UPLOAD_SPARSE_STREAM
        * @acl: storage_vol:data_write
        */
        REMOTE_PROC_STORAGE_VOL_UPLOAD = 208,
      }
      """

      {:ok, parsed, _, _, _, _} = CallParser.parse(code)
      assert parsed == [{:procedure, ["writestream", "REMOTE_PROC_STORAGE_VOL_UPLOAD", 208]}]
    end
  end

  def get_structs(code) do
    {:ok, parsed, _, _, _, _} = CallParser.parse(code)
    Enum.filter(parsed, fn {type, _val} -> type == :struct end)
  end

  describe "structs" do
    test "remote_domain_backup_get_xml_desc_ret" do
      code = """
      struct remote_domain_backup_get_xml_desc_ret {
          remote_nonnull_string xml;
      };
      """

      structs = get_structs(code)

      assert structs == [
               struct: [
                 name: "domain_backup_get_xml_desc_ret",
                 fields: [["remote_nonnull_string", "xml"]]
               ]
             ]
    end

    test "remote_connect_supports_feature_args - basic struct" do
      code = """
      struct remote_connect_supports_feature_args {
          int feature;
      };
      """

      structs = get_structs(code)

      assert structs == [
               struct: [
                 name: "connect_supports_feature_args",
                 fields: [["int", "feature"]]
               ]
             ]
    end

    test "remote_connect_open_args - struct with comments" do
      code = """
      struct remote_connect_open_args {
          /* NB. "name" might be NULL although in practice you can't
          * yet do that using the remote_internal driver.
          */
          remote_string name;
          unsigned int flags;
      };
      """

      structs = get_structs(code)

      assert structs == [
               struct: [
                 name: "connect_open_args",
                 fields: [["remote_string", "name"], ["unsigned", "int", "flags"]]
               ]
             ]
    end

    test "remote_node_get_cpu_stats_ret - using a list" do
      code = """
      struct remote_node_get_cpu_stats_ret {
        remote_node_get_cpu_stats params<REMOTE_NODE_CPU_STATS_MAX>;
        int nparams;
      };
      """

      structs = get_structs(code)

      assert structs == [
               struct: [
                 name: "node_get_cpu_stats_ret",
                 fields: [
                   [
                     "remote_node_get_cpu_stats",
                     {:list, ["params", "REMOTE_NODE_CPU_STATS_MAX"]}
                   ],
                   ["int", "nparams"]
                 ]
               ]
             ]
    end

    test "remote_domain_get_info_ret - mixed case" do
      code = """
      struct remote_domain_get_info_ret { /* insert@1 */
          unsigned char state;
          unsigned hyper maxMem;
          unsigned hyper memory;
          unsigned short nrVirtCpu;
          unsigned hyper cpuTime;
      };
      """

      structs = get_structs(code)

      assert structs == [
               struct: [
                 name: "domain_get_info_ret",
                 fields: [
                   ["unsigned", "char", "state"],
                   ["unsigned", "hyper", "maxMem"],
                   ["unsigned", "hyper", "memory"],
                   ["unsigned", "short", "nrVirtCpu"],
                   ["unsigned", "hyper", "cpuTime"]
                 ]
               ]
             ]
    end

    test "remote_node_get_info_ret - edge case unknown" do
      code = """
      struct remote_node_get_info_ret { /* insert@1 */
          char model[32];
          unsigned hyper memory;
          int cpus;
          int mhz;
          int nodes;
          int sockets;
          int cores;
          int threads;
      };
      """

      structs = get_structs(code)
      assert structs == [
        struct: [
          name: "node_get_info_ret",
          fields: [
            ["char", "model", "32"],
            ["unsigned", "hyper", "memory"],
            ["int", "cpus"],
            ["int", "mhz"],
            ["int", "nodes"],
            ["int", "sockets"],
            ["int", "cores"],
            ["int", "threads"]
          ]
        ]
      ]
    end
  end
end
