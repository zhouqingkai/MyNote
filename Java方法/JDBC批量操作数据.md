#### JDBC批量操作数据

10w条数据大概1.2秒

```java
private String url = "jdbc:mysql://localhost:3306/test01?rewriteBatchedStatements=true";
  private String user = "root";
  private String password = "123456";
  @Test
  public void Test(){
    Connection conn = null;
    PreparedStatement pstm =null;
    ResultSet rt = null;
    try {
      Class.forName("com.mysql.jdbc.Driver");
      conn = DriverManager.getConnection(url, user, password);   
      String sql = "INSERT INTO myTable values(?,?)";
      pstm = conn.prepareStatement(sql);
      Long startTime = System.currentTimeMillis();
      conn.setAutoCommit(false);
      for (int i = 1; i <= 100000; i++) {
          pstm.setInt(1, i);
          pstm.setInt(2, i);
          pstm.addBatch();
      }
      pstm.executeBatch();
      conn.commit();
      Long endTime = System.currentTimeMillis();
      System.out.println("用时：" + (endTime - startTime));
    } catch (Exception e) {
      e.printStackTrace();
      throw new RuntimeException(e);
    }finally{
      if(pstm!=null){
        try {
          pstm.close();
        } catch (SQLException e) {
          e.printStackTrace();
          throw new RuntimeException(e);
        }
      }
      if(conn!=null){
        try {
          conn.close();
        } catch (SQLException e) {
          e.printStackTrace();
          throw new RuntimeException(e);
        }
      }
    }
  }
```

